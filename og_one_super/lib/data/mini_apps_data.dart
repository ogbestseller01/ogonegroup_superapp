import '../models/mini_app.dart';

const List<MiniApp> miniApps = [
  // Featured (live)
  MiniApp(
    id: 1,
    slug: 'nearbyfundi',
    name: 'NearbyFundi',
    subtitle: 'Find & hire fundis',
    icon: 'build',
    color: '#1E6BFF',
    isComingSoon: false,
  ),
  MiniApp(
    id: 2,
    slug: 'fundiapp',
    name: 'Fundi App',
    subtitle: 'For fundis & technicians',
    icon: 'handyman',
    color: '#FFA000',
    isComingSoon: false,
  ),

  // Partner’s apps
  MiniApp(
    id: 3,
    slug: 'msosi',
    name: 'Msosi Chap Chap',
    subtitle: 'Order food fast',
    icon: 'fastfood',
    color: '#E65100',
    isComingSoon: true,
  ),
  MiniApp(
    id: 5,
    slug: 'laundry',
    name: 'Mfua Nguo',
    subtitle: 'Laundry near you',
    icon: 'local_laundry_service',
    color: '#0277BD',
    isComingSoon: true,
  ),
  MiniApp(
    id: 6,
    slug: 'osha',
    name: 'Osha Papo Hapo',
    subtitle: 'Car wash at your spot',
    icon: 'local_car_wash',
    color: '#00897B',
    isComingSoon: true,
  ),
  MiniApp(
    id: 7,
    slug: 'hama',
    name: 'Hama Chap Chap',
    subtitle: 'Moving & relocation fast',
    icon: 'local_shipping',
    color: '#5E35B1',
    isComingSoon: true,
  ),
  MiniApp(
    id: 11,
    slug: 'duma',
    name: 'Duma App',
    subtitle: 'Delivery services',
    icon: 'delivery_dining',
    color: '#6D4C41',
    isComingSoon: true,
  ),
  MiniApp(
    id: 10,
    slug: 'nimepoteza',
    name: 'Nimepoteza App',
    subtitle: 'Report & find lost items',
    icon: 'find_in_page',
    color: '#F5C30E',
    isComingSoon: true,
  ),
];