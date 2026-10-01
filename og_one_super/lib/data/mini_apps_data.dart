// lib/data/mini_apps_data.dart

import '../models/mini_app.dart';

const List<MiniApp> miniApps = [
  MiniApp(
    id: 1,
    slug: 'nearbyfundi',
    name: 'NearbyFundi',
    subtitle: 'Find & hire fundis',
    icon: 'build',
    color: '#001D45',
  ),
  MiniApp(
    id: 2,
    slug: 'fundiapp',
    name: 'Fundi App',
    subtitle: 'For fundis & technicians',
    icon: 'handyman',
    color: '#0A3670',
  ),
  MiniApp(
    id: 3,
    slug: 'msosi',
    name: 'Msosi Chap Chap',
    subtitle: 'Order food fast',
    icon: 'fastfood',
    color: '#E65100',
  ),
  MiniApp(
    id: 4,
    slug: 'health',
    name: 'Nearby Health Facility',
    subtitle: 'Find health facilities',
    icon: 'local_hospital',
    color: '#0A8A6D',
  ),
  MiniApp(
    id: 5,
    slug: 'hotel',
    name: 'Nearby Hotel',
    subtitle: 'Hotels & lodges nearby',
    icon: 'hotel',
    color: '#6A1B9A',
  ),
  MiniApp(
    id: 6,
    slug: 'laundry',
    name: 'Mfua Nguo',
    subtitle: 'Laundry near you',
    icon: 'local_laundry_service',
    color: '#0277BD',
  ),
  MiniApp(
    id: 7,
    slug: 'coming_soon',
    name: 'Coming Soon',
    subtitle: 'More apps coming',
    icon: 'apps',
    color: '#F5C30E',
    isComingSoon: true,
  ),
];