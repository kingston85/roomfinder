/// Fixed lists used by forms and filters. Edit these to add places.

const counties = [
  'Montserrado',
  'Margibi',
  'Bong',
  'Grand Bassa',
  'Nimba',
];

const communities = [
  'Sinkor',
  'Congo Town',
  'Paynesville',
  'ELWA',
  'Red Light',
  'Old Road',
  'Gardnersville',
  'Barnersville',
  'Duport Road',
  'Johnsonville',
  'Brewerville',
  'Logan Town',
  'Bushrod Island',
  'Clara Town',
  'New Kru Town',
  'Capitol Hill',
  'Mamba Point',
  'Central Monrovia',
  'Caldwell',
  'Virginia',
  'Chocolate City',
  'Fiamah',
  'Jallah Town',
  'Other',
];

/// Listing types: stored key -> label shown to people.
const listingTypes = <String, String>{
  'single_room': 'Single room',
  'room_parlor': 'Room and parlour',
  'apartment_1': '1-bedroom apartment',
  'apartment_2': '2-bedroom apartment',
  'apartment_3': '3+ bedroom apartment',
  'house': 'Whole house',
  'shop': 'Shop / store space',
};

/// Amenities: stored key -> label.
const amenityLabels = <String, String>{
  'water_inside': 'Running water inside',
  'water_well': 'Pump or well on compound',
  'lec_power': 'LEC current',
  'backup_power': 'Generator or solar',
  'fence_gate': 'Fence and gate',
  'toilet_inside': 'Toilet inside',
  'kitchen': 'Kitchen',
  'parking': 'Parking',
  'good_road': 'Good road in rainy season',
};

const reportReasons = <String, String>{
  'taken': 'Already taken',
  'fake': 'Fake or does not exist',
  'wrong_price': 'Wrong price',
  'scam': 'Asked for money before viewing / scam',
  'other': 'Something else',
};

String typeLabel(String key) => listingTypes[key] ?? key;
