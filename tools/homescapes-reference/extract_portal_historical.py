#!/usr/bin/env python3
"""Extract the original yellow and blue portal candidates from the historical APK."""
from pathlib import Path
import extract_historical_art

extract_historical_art.REGIONS = Path(__file__).with_name('portal-historical-regions.json')
extract_historical_art.main()
