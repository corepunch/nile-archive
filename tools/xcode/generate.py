#!/usr/bin/env python3
"""Generate the native Xcode project of a game: games/<game>/<game>.xcodeproj.

    tools/xcode/generate.py nile-archive --unsigned     # nile-archive-macos, nile-archive-ipad
    tools/xcode/generate.py relic-rush --unsigned       # relic-rush-macos, relic-rush-iphone
    tools/xcode/generate.py --check            # fail if a committed project is stale (make test)

After orion-ui's tools/xcode/generate.py: the project file is written directly
with deterministic identifiers (a hash of what each object is), together with
the Generated/ Info.plists and entitlements and the shared schemes, and the
result is committed beside the game so Xcode and Xcode Cloud find it without
any tool. Each project has a macOS target and an iOS one, iPad for Nile Archive and
iPhone for Relic Rush; both compile the engine
and link SDL2 from engine/third_party/SDL's own Xcode project, which is added
as a project reference and built as a dependency, so no SDL package needs to
be installed. The game's lua/ and data/ folders are bundled as folder
references and found at run time through SDL_GetBasePath (GAME_IN_BUNDLE).
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import sys
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
SDL = 'engine/third_party/SDL'
SDL_PROJECT = SDL + '/Xcode/SDL/SDL.xcodeproj'
ENGINE_SOURCES = ['core', 'gfx', 'font', 'ui', 'save', 'city', 'audio', 'story', 'script', 'api_lua']   # as in the Makefile

GAMES = {
    # device: the iOS target - 'ipad' (device family 2) or 'iphone' (family 1)
    'nile-archive': dict(name='Nile Archive', bundle='com.corepunch.nilearchive', device='ipad', orientations=('LandscapeLeft', 'LandscapeRight')),
    'relic-rush': dict(name='Relic Rush', bundle='com.corepunch.relicrush', device='iphone', orientations=('Portrait', 'PortraitUpsideDown')),
}


def write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists() or path.read_text() != content:
        path.write_text(content)


def encode(value):
    if isinstance(value, dict):
        return '{' + ''.join(f'{encode(k)} = {encode(v)};\n' for k, v in value.items()) + '}'
    if isinstance(value, list):
        return '(' + ''.join(f'{encode(v)},\n' for v in value) + ')'
    if isinstance(value, int):
        return str(value)
    return json.dumps(str(value))


def decode(text):
    """Parse a project written by encode() (the subset of the plist format it uses)."""
    pos = text.index('{')

    def skip():
        nonlocal pos
        while pos < len(text) and text[pos] in ' \t\r\n':
            pos += 1

    def value():
        nonlocal pos
        skip()
        c = text[pos]
        if c == '{':
            pos += 1
            out = {}
            while True:
                skip()
                if text[pos] == '}':
                    pos += 1
                    return out
                k = value()
                skip()
                assert text[pos] == '='
                pos += 1
                out[k] = value()
                skip()
                assert text[pos] == ';'
                pos += 1
        if c == '(':
            pos += 1
            out = []
            while True:
                skip()
                if text[pos] == ')':
                    pos += 1
                    return out
                out.append(value())
                skip()
                assert text[pos] == ','
                pos += 1
        if c == '"':
            end = pos + 1
            while text[end] != '"':
                end += 2 if text[end] == '\\' else 1
            s = json.loads(text[pos:end + 1])
            pos = end + 1
            return s
        m = re.match(r'-?\d+', text[pos:])
        pos += m.end()
        return int(m.group())

    return value()


def read_project(path):
    if not path.is_file():
        return {}
    try:
        return decode(path.read_text())['objects']
    except (AssertionError, ValueError, KeyError, IndexError):
        return {}   # not written by this generator: start afresh


def sdl_targets():
    """SDL's framework targets, by name: (target id, product file reference id)."""
    text = (ROOT / SDL_PROJECT / 'project.pbxproj').read_text()
    found = {}
    for m in re.finditer(r'(\w{24}) /\* ([^*]+) \*/ = \{\n\t\t\tisa = PBXNativeTarget;(.*?)\n\t\t\};', text, re.S):
        product = re.search(r'productReference = (\w{24})', m.group(3))
        if product:
            found[m.group(2)] = (m.group(1), product.group(1))
    for name in ('Framework', 'Framework-iOS'):
        if name not in found:
            sys.exit(f'{SDL_PROJECT}: target {name!r} not found; is the SDL submodule checked out?')
    return found


class Project:
    def __init__(self, existing):
        self.objects = {}
        self.existing = existing

    def add(self, key, isa, **fields):
        uid = hashlib.sha256(key.encode()).hexdigest()[:24].upper()
        if uid in self.objects:
            raise ValueError(f'Duplicate project object: {key}')
        self.objects[uid] = dict(isa=isa, **fields)
        return uid

    def configurations(self, key, settings):
        configs = []
        for name in ('Debug', 'Release'):
            values = dict(settings, GCC_OPTIMIZATION_LEVEL='0' if name == 'Debug' else 's',
                          DEBUG_INFORMATION_FORMAT='dwarf' if name == 'Debug' else 'dwarf-with-dsym',
                          ONLY_ACTIVE_ARCH='YES' if name == 'Debug' else 'NO')
            uid = self.add(f'{key}/{name}', 'XCBuildConfiguration', name=name, buildSettings=values)
            for field, value in self.existing.get(uid, {}).get('buildSettings', {}).items():
                if field.startswith(('CODE_SIGN', 'DEVELOPMENT_TEAM', 'PROVISIONING_PROFILE', 'PRODUCT_BUNDLE_IDENTIFIER')):
                    values[field] = value
            configs.append(uid)
        return self.add(f'{key}/configurations', 'XCConfigurationList', buildConfigurations=configs,
                        defaultConfigurationIsVisible=0, defaultConfigurationName='Debug')


def scheme(path, project_name, game, name, target):
    root = ET.Element('Scheme', LastUpgradeVersion='1600', version='1.3')
    action = ET.SubElement(root, 'BuildAction', parallelizeBuildables='YES', buildImplicitDependencies='YES')
    entries = ET.SubElement(action, 'BuildActionEntries')
    entry = ET.SubElement(entries, 'BuildActionEntry', **{f'buildFor{k}': 'YES' for k in
                          ('Testing', 'Running', 'Profiling', 'Archiving', 'Analyzing')})
    reference = dict(BuildableIdentifier='primary', BlueprintIdentifier=target,
                     BuildableName=game + '.app', BlueprintName=name, ReferencedContainer=f'container:{project_name}')
    ET.SubElement(entry, 'BuildableReference', **reference)
    for tag, config in (('LaunchAction', 'Debug'), ('ProfileAction', 'Release')):
        action = ET.SubElement(root, tag, buildConfiguration=config, useCustomWorkingDirectory='NO')
        if tag == 'LaunchAction':
            action.set('selectedDebuggerIdentifier', 'Xcode.DebuggerFoundation.Debugger.LLDB')
            action.set('selectedLauncherIdentifier', 'Xcode.IDEFoundation.Launcher.LLDB')
        runnable = ET.SubElement(action, 'BuildableProductRunnable', runnableDebuggingMode='0')
        ET.SubElement(runnable, 'BuildableReference', **reference)
    ET.SubElement(root, 'AnalyzeAction', buildConfiguration='Debug')
    ET.SubElement(root, 'ArchiveAction', buildConfiguration='Release', revealArchiveInOrganizer='YES')
    ET.indent(root)
    write(path, '<?xml version="1.0" encoding="UTF-8"?>\n' + ET.tostring(root, encoding='unicode') + '\n')


def generate(game, output, unsigned=True, bundle_id=None, team=None, settings_from=None, home=None):
    """home: the folder the project is meant to live in (paths are relative to it); default games/<game>."""
    meta = GAMES[game]
    bundle_id = bundle_id or meta['bundle']
    output = output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    bundle = output / (game + '.xcodeproj')
    existing = read_project((settings_from or bundle) / 'project.pbxproj')
    project = Project(existing if unsigned else {})
    home = (home or ROOT / 'games' / game).resolve()
    rel = lambda p: os.path.relpath(ROOT / p, home)   # paths in the project are relative to the game folder
    engine_root = '$(SRCROOT)/' + rel('.')
    sdl = sdl_targets()

    common = {
        'ENGINE_ROOT': engine_root,
        'SDKROOT': 'macosx', 'GCC_C_LANGUAGE_STANDARD': 'c11', 'CLANG_ENABLE_OBJC_ARC': 'NO',
        'ENABLE_USER_SCRIPT_SANDBOXING': 'NO', 'ALWAYS_SEARCH_USER_PATHS': 'NO',
        'GCC_WARN_INHIBIT_ALL_WARNINGS': 'NO', 'GCC_WARN_ABOUT_RETURN_TYPE': 'YES',
        'HEADER_SEARCH_PATHS': ['$(ENGINE_ROOT)/engine', '$(ENGINE_ROOT)/' + SDL + '/include'],
        'GCC_PREPROCESSOR_DEFINITIONS': ['$(inherited)', 'GAME_IN_BUNDLE=1', f'GAME_DIR=\\"games/{game}\\"'],
        'OTHER_CFLAGS': ['$(inherited)', '-Wall', '-Wextra', '-Wno-unused-parameter', '-Wno-missing-field-initializers',
                         '-Wno-deprecated-declarations'],
        'PRODUCT_NAME': game, 'PRODUCT_BUNDLE_IDENTIFIER': bundle_id,
        'MARKETING_VERSION': '1.0', 'CURRENT_PROJECT_VERSION': '1',
        'ENABLE_HARDENED_RUNTIME': 'NO',
    }
    root_configs = project.configurations('project', common)

    # --- files and groups ---
    sources = {}
    for name in ENGINE_SOURCES + ['lua_lib', 'launcher']:
        sources[name] = project.add('engine/' + name, 'PBXFileReference', path=rel(f'engine/{name}.c'),
                                    name=name + '.c', sourceTree='SOURCE_ROOT', lastKnownFileType='sourcecode.c.c')
    header = project.add('engine/engine.h', 'PBXFileReference', path=rel('engine/engine.h'), name='engine.h',
                         sourceTree='SOURCE_ROOT', lastKnownFileType='sourcecode.c.h')
    api = project.add('engine/api.xml', 'PBXFileReference', path=rel('engine/api.xml'), name='api.xml',
                      sourceTree='SOURCE_ROOT', lastKnownFileType='text.xml')
    lua_folder = project.add('game/lua', 'PBXFileReference', path='lua', sourceTree='<group>', lastKnownFileType='folder')
    data_folder = project.add('game/data', 'PBXFileReference', path='data', sourceTree='<group>', lastKnownFileType='folder')
    sdl_ref = project.add('sdl/project', 'PBXFileReference', name='SDL.xcodeproj', path=rel(SDL_PROJECT),
                          sourceTree='SOURCE_ROOT', lastKnownFileType='wrapper.pb-project')
    sdl_products = []
    sdl_proxies = {}
    for target_name, (target_id, product_id) in sdl.items():
        if target_name not in ('Framework', 'Framework-iOS'):
            continue
        item = project.add(f'sdl/{target_name}/product-proxy', 'PBXContainerItemProxy', containerPortal=sdl_ref,
                           proxyType=2, remoteGlobalIDString=product_id, remoteInfo=target_name)
        proxy = project.add(f'sdl/{target_name}/product', 'PBXReferenceProxy', fileType='wrapper.framework',
                            path='SDL2.framework', remoteRef=item, sourceTree='BUILT_PRODUCTS_DIR')
        sdl_products.append(proxy)
        sdl_proxies[target_name] = (target_id, proxy)
    sdl_group = project.add('sdl/products', 'PBXGroup', name='Products', children=sdl_products, sourceTree='<group>')
    browse = [
        project.add('group/game', 'PBXGroup', name='Game', children=[lua_folder, data_folder], sourceTree='<group>'),
        project.add('group/engine', 'PBXGroup', name='Engine',
                    children=[header, api] + [sources[n] for n in ENGINE_SOURCES + ['lua_lib', 'launcher']], sourceTree='<group>'),
        project.add('group/sdl', 'PBXGroup', name='SDL', children=[sdl_ref], sourceTree='<group>'),
    ]

    # --- targets ---
    targets, products = [], []
    for platform in ('macos', meta['device']):
        name = f'{game}-{platform}'
        ipad = platform != 'macos'   # the iOS target, iPad or iPhone
        sdl_target, sdl_product = sdl_proxies['Framework-iOS' if ipad else 'Framework']
        settings = dict(INFOPLIST_FILE=f'$(PROJECT_FILE_PATH)/Generated/{"ios" if ipad else "macos"}-Info.plist',
                        OTHER_LDFLAGS=['$(inherited)', '-lm'],
                        LD_RUNPATH_SEARCH_PATHS=['$(inherited)', '@executable_path/Frameworks' if ipad else '@executable_path/../Frameworks'])
        if ipad:
            settings.update(CODE_SIGN_STYLE='Automatic', SDKROOT='iphoneos', SUPPORTED_PLATFORMS='iphoneos iphonesimulator',
                            IPHONEOS_DEPLOYMENT_TARGET='16.0', TARGETED_DEVICE_FAMILY='1' if platform == 'iphone' else '2',
                            SUPPORTS_MACCATALYST='NO')
        else:
            settings.update(SUPPORTED_PLATFORMS='macosx', MACOSX_DEPLOYMENT_TARGET='12.0',
                            CODE_SIGN_STYLE='Automatic', CODE_SIGN_IDENTITY='-',
                            ENABLE_APP_SANDBOX='YES',
                            CODE_SIGN_ENTITLEMENTS='$(PROJECT_FILE_PATH)/Generated/macos.entitlements')
            write(bundle / 'Generated/macos.entitlements', plistlib.dumps({'com.apple.security.app-sandbox': True}).decode())
        if team:
            settings['DEVELOPMENT_TEAM'] = team
        configs = project.configurations(name, settings)

        info = dict(CFBundleExecutable='$(EXECUTABLE_NAME)', CFBundleIdentifier='$(PRODUCT_BUNDLE_IDENTIFIER)',
                    CFBundleName=meta['name'], CFBundleDisplayName=meta['name'], CFBundlePackageType='APPL',
                    CFBundleInfoDictionaryVersion='6.0', CFBundleShortVersionString='$(MARKETING_VERSION)',
                    CFBundleVersion='$(CURRENT_PROJECT_VERSION)', CFBundleDevelopmentRegion='en',
                    LSApplicationCategoryType='public.app-category.games', ITSAppUsesNonExemptEncryption=False)
        if ipad:
            info.update(LSRequiresIPhoneOS=True, UIRequiresFullScreen=True, UIStatusBarHidden=True,
                        UIViewControllerBasedStatusBarAppearance=False, UILaunchScreen={},
                        UISupportedInterfaceOrientations=['UIInterfaceOrientation' + o for o in meta['orientations']],
                        UIRequiredDeviceCapabilities=['arm64'])
        else:
            info.update(NSHighResolutionCapable=True, NSPrincipalClass='NSApplication')
        write(bundle / 'Generated' / (('ios' if ipad else 'macos') + '-Info.plist'), plistlib.dumps(info).decode())

        build_files = []
        for filename, ref in sources.items():
            fields = {'fileRef': ref}
            if filename == 'lua_lib':
                fields['settings'] = {'COMPILER_FLAGS': '-Wno-unused-function'}
            build_files.append(project.add(f'{name}/{filename}.c', 'PBXBuildFile', **fields))
        compile_phase = project.add(name + '/sources', 'PBXSourcesBuildPhase', buildActionMask=2147483647,
                                    files=build_files, runOnlyForDeploymentPostprocessing=0)
        link = project.add(name + '/link-sdl', 'PBXBuildFile', fileRef=sdl_product)
        link_phase = project.add(name + '/frameworks', 'PBXFrameworksBuildPhase', buildActionMask=2147483647,
                                 files=[link], runOnlyForDeploymentPostprocessing=0)
        embed = project.add(name + '/embed-sdl', 'PBXBuildFile', fileRef=sdl_product,
                            settings={'ATTRIBUTES': ['CodeSignOnCopy', 'RemoveHeadersOnCopy']})
        embed_phase = project.add(name + '/embed', 'PBXCopyFilesBuildPhase', buildActionMask=2147483647, dstPath='',
                                  dstSubfolderSpec=10, files=[embed], name='Embed Frameworks', runOnlyForDeploymentPostprocessing=0)
        resource_files = [project.add(f'{name}/{folder}', 'PBXBuildFile', fileRef=ref) for folder, ref in (('lua', lua_folder), ('data', data_folder))]
        resources_phase = project.add(name + '/resources', 'PBXResourcesBuildPhase', buildActionMask=2147483647,
                                      files=resource_files, runOnlyForDeploymentPostprocessing=0)
        dependency_proxy = project.add(name + '/sdl-target-proxy', 'PBXContainerItemProxy', containerPortal=sdl_ref,
                                       proxyType=1, remoteGlobalIDString=sdl_target, remoteInfo='Framework-iOS' if ipad else 'Framework')
        dependency = project.add(name + '/sdl-dependency', 'PBXTargetDependency', name='Framework-iOS' if ipad else 'Framework',
                                 targetProxy=dependency_proxy)
        product = project.add(name + '/product', 'PBXFileReference', path=game + '.app', sourceTree='BUILT_PRODUCTS_DIR',
                              explicitFileType='wrapper.application')
        products.append(product)
        target = project.add(name, 'PBXNativeTarget', name=name, productName=game, productReference=product,
                             productType='com.apple.product-type.application', buildConfigurationList=configs,
                             buildPhases=[compile_phase, link_phase, resources_phase, embed_phase], buildRules=[],
                             dependencies=[dependency])
        targets.append(target)
        scheme_path = bundle / 'xcshareddata/xcschemes' / (name + '.xcscheme')
        if not scheme_path.exists():
            scheme(scheme_path, bundle.name, game, name, target)

    products_group = project.add('group/products', 'PBXGroup', name='Products', children=products, sourceTree='<group>')
    main_group = project.add('group/main', 'PBXGroup', children=browse + [products_group], sourceTree='<group>')
    root = project.add('project', 'PBXProject', buildConfigurationList=root_configs, compatibilityVersion='Xcode 14.0',
                       developmentRegion='en', knownRegions=['en', 'Base'], mainGroup=main_group,
                       productRefGroup=products_group, projectDirPath='', projectRoot='',
                       projectReferences=[{'ProductGroup': sdl_group, 'ProjectRef': sdl_ref}], targets=targets)
    if existing.get(root, {}).get('attributes'):
        project.objects[root]['attributes'] = existing[root]['attributes']
    write(bundle / 'project.pbxproj', '// !$*UTF8*$!\n' + encode(dict(
        archiveVersion=1, classes={}, objectVersion=56, objects=project.objects, rootObject=root)) + '\n')
    return bundle


def check():
    """Regenerate every game's project in a temporary folder and compare with the committed one."""
    stale = []
    for game in GAMES:
        committed = ROOT / 'games' / game / (game + '.xcodeproj')
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / 'games' / game   # same depth, so relative paths come out the same
            out.mkdir(parents=True)
            fresh = generate(game, out, settings_from=committed, home=committed.parent)
            for path in sorted(fresh.rglob('*')):
                if path.is_file() and path.name != '.DS_Store':
                    other = committed / path.relative_to(fresh)
                    if not other.is_file() or other.read_text() != path.read_text():
                        stale.append(str(other.relative_to(ROOT)))
    if stale:
        sys.exit('out of date (run tools/xcode/generate.py <game> --unsigned): ' + ', '.join(stale))


def main():
    parser = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    parser.add_argument('game', nargs='?', choices=sorted(GAMES))
    parser.add_argument('--output', type=Path, help='Project parent directory (default: games/<game>)')
    parser.add_argument('--settings-from', type=Path, help='Preserve signing settings from an existing .xcodeproj')
    parser.add_argument('--bundle-id')
    parser.add_argument('--team', default=os.environ.get('TEAM'))
    parser.add_argument('--unsigned', action='store_true', help='Automatic signing without a team; configure it in Xcode later')
    parser.add_argument('--check', action='store_true', help='Fail if the committed projects differ from a fresh generation')
    args = parser.parse_args()
    if args.check:
        check()
        return
    if not args.game:
        parser.error('name a game or pass --check')
    print(generate(args.game, args.output or ROOT / 'games' / args.game, unsigned=args.unsigned or not args.team,
                   bundle_id=args.bundle_id, team=args.team, settings_from=args.settings_from))


if __name__ == '__main__':
    main()
