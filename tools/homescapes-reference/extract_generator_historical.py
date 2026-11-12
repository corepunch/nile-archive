#!/usr/bin/env python3
"""Extract historical generator components with the common APK decoder."""
from pathlib import Path
import extract_historical_art

extract_historical_art.REGIONS = Path(__file__).with_name('generator-historical-regions.json')
extract_historical_art.main()
