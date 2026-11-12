"""Regression checks for the locally supplied Homescapes quest binary."""
import unittest
import zipfile

from story_index import SOURCE, decode
from story_outline import parse


@unittest.skipUnless(SOURCE.exists(), 'Homescapes bundle unavailable')
class QuestOutlineTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with zipfile.ZipFile(SOURCE) as archive:
            cls.hall = decode(archive.read('base_mm/cluster1/CH_Hall/Quest.xml.au'))
            cls.all_days = [parse(decode(archive.read(name))) for name in archive.namelist()
                            if name.endswith('/Quest.xml.au')]

    def test_hall_opening_array_and_offsets(self):
        days = parse(self.hall)
        self.assertEqual(days[0]['label'], 'Ostin room: Day 1')
        self.assertEqual([task['id'] for task in days[0]['tasks'][:3]], [
            'CH_OstinsRoom_Homecoming', 'CH_OstinsRoom_ReplaceCarpet',
            'CH_OstinsRoom_CleanRoom'])
        self.assertEqual(days[0]['tasks'][1]['title_key'],
                         'CH_OstinsRoom_ReplaceCarpet_Title')
        self.assertEqual(days[1]['label'], 'Hall: Day 1')

    def test_all_bundled_quest_arrays(self):
        self.assertEqual(len(self.all_days), 48)
        self.assertEqual(sum(len(days) for days in self.all_days), 285)
        self.assertEqual(sum(len(day['tasks']) for days in self.all_days for day in days), 6078)
        self.assertTrue(all(task['title_key'] for days in self.all_days for day in days
                            for task in day['tasks']))

    def test_truncated_data_rejected(self):
        for length in (0, 27, 100):
            with self.subTest(length=length), self.assertRaises((ValueError, UnicodeError)):
                parse(self.hall[:length])


if __name__ == '__main__':
    unittest.main()
