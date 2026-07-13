/// Philippine geographic data: Region → City/Municipality → Barangays
/// Used for cascading dropdown selection throughout the app.
library ph_location_data;

// ── Data model ────────────────────────────────────────────────────────────────

class PhRegion {
  final String name;
  final List<PhCity> cities;
  const PhRegion({required this.name, required this.cities});
}

class PhCity {
  final String name;
  final List<String> barangays;
  const PhCity({required this.name, required this.barangays});
}

// ── Lookup helpers ────────────────────────────────────────────────────────────

PhRegion? regionByName(String name) =>
    phRegions.where((r) => r.name == name).firstOrNull;

PhCity? cityByName(PhRegion region, String name) =>
    region.cities.where((c) => c.name == name).firstOrNull;

List<String> regionNames() => phRegions.map((r) => r.name).toList();

List<String> cityNames(String regionName) =>
    regionByName(regionName)?.cities.map((c) => c.name).toList() ?? [];

List<String> barangayNames(String regionName, String cityName) {
  final region = regionByName(regionName);
  if (region == null) return [];
  return cityByName(region, cityName)?.barangays ?? [];
}

// ── Data ──────────────────────────────────────────────────────────────────────

const List<PhRegion> phRegions = [
  // ── NCR ───────────────────────────────────────────────────────────────────
  PhRegion(name: 'NCR – National Capital Region', cities: [
    PhCity(name: 'Manila', barangays: [
      'Binondo', 'Ermita', 'Intramuros', 'Malate', 'Paco', 'Pandacan',
      'Port Area', 'Quiapo', 'Sampaloc', 'San Andres', 'San Miguel',
      'San Nicolas', 'Santa Ana', 'Santa Cruz', 'Santa Mesa', 'Tondo',
    ]),
    PhCity(name: 'Quezon City', barangays: [
      'Bagumbayan', 'Batasan Hills', 'Commonwealth', 'Cubao', 'Diliman',
      'Fairview', 'Holy Spirit', 'Kamuning', 'Krus na Ligas', 'Loyola Heights',
      'Matandang Balara', 'New Era', 'Novaliches Proper', 'Pansol', 'Payatas',
      'Project 4', 'Project 6', 'Quirino District', 'San Bartolome',
      'Tandang Sora', 'UP Campus', 'Vasra', 'West Triangle',
    ]),
    PhCity(name: 'Caloocan', barangays: [
      'Bagong Silang', 'Camarin', 'Dagat-Dagatan', 'Deparo', 'Grace Park',
      'Kaunlaran', 'Maypajo', 'Monumento', 'NBBS', 'Tala',
    ]),
    PhCity(name: 'Makati', barangays: [
      'Ayala Alabang', 'Bangkal', 'Bel-Air', 'Carmona', 'Cembo',
      'Dasmariñas', 'Forbes Park', 'Guadalupe Nuevo', 'Guadalupe Viejo',
      'Kasilawan', 'La Paz', 'Legazpi Village', 'Palanan', 'Pembo',
      'Pinagkaisahan', 'Pitogo', 'Poblacion', 'Pio Del Pilar', 'Rizal',
      'Rockwell', 'Salcedo Village', 'San Antonio', 'San Isidro',
      'San Lorenzo', 'Santa Cruz', 'Singkamas', 'South Cembo', 'Tejeros',
      'Urdaneta', 'Valenzuela', 'West Rembo',
    ]),
    PhCity(name: 'Taguig', barangays: [
      'Bagumbayan', 'Bambang', 'Calzada', 'Central Bicutan', 'Central Signal Village',
      'Fort Bonifacio', 'Hagonoy', 'Ibayo-Tipas', 'Katuparan', 'Ligid-Tipas',
      'Lower Bicutan', 'Maharlika Village', 'Napindan', 'New Lower Bicutan',
      'North Daang Hari', 'North Signal Village', 'Palingon', 'Pinagsama',
      'San Miguel', 'Santa Ana', 'South Daang Hari', 'South Signal Village',
      'Tuktukan', 'Upper Bicutan', 'Ususan', 'Wawa', 'Western Bicutan',
    ]),
    PhCity(name: 'Pasig', barangays: [
      'Bagong Ilog', 'Bagong Katipunan', 'Bambang', 'Buting', 'Caniogan',
      'dela Paz', 'Kalawaan', 'Kapasigan', 'Kapitolyo', 'Malinao',
      'Manggahan', 'Maybunga', 'Oranbo', 'Palatiw', 'Pineda', 'Pinagbuhatan',
      'Rosario', 'Sagad', 'San Antonio', 'San Joaquin', 'San Jose',
      'San Miguel', 'San Nicolas', 'Santa Lucia', 'Santa Rosa', 'Santo Tomas',
      'Santolan', 'Sumilang', 'Ugong',
    ]),
    PhCity(name: 'Mandaluyong', barangays: [
      'Addition Hills', 'Bagong Silang', 'Barangka Drive', 'Buayang Bato',
      'Burol', 'Daang Bakal', 'Hagdan Bato Itaas', 'Hagdan Bato Libis',
      'Harapin Ang Bukas', 'Highway Hills', 'Hulo', 'Mabini-J. Rizal',
      'Malamig', 'Mauway', 'Namayan', 'New Zañiga', 'Old Zaniga', 'Pag-asa',
      'Plainview', 'Pleasant Hills', 'Poblacion', 'Saint Francis',
      'Vergara', 'Wack-Wack Greenhills',
    ]),
    PhCity(name: 'Parañaque', barangays: [
      'Baclaran', 'BF Homes', 'Don Galo', 'Doña Soledad', 'La Huerta',
      'Marcelo Green', 'Merville', 'Moonshine', 'San Dionisio', 'San Isidro',
      'San Martin de Porres', 'Santo Niño', 'Sucat', 'Sun Valley',
    ]),
    PhCity(name: 'Las Piñas', barangays: [
      'Almanza Uno', 'Almanza Dos', 'BF International', 'Daniel Fajardo',
      'Elias Aldana', 'Ilaya', 'Manuyo Uno', 'Manuyo Dos', 'Pamplona Uno',
      'Pamplona Dos', 'Pamplona Tres', 'Pilar', 'Pulang Lupa Uno',
      'Pulang Lupa Dos', 'Talon Uno', 'Talon Dos', 'Talon Tres',
      'Talon Kuatro', 'Talon Singko', 'Victoria',
    ]),
    PhCity(name: 'Marikina', barangays: [
      'Barangka', 'Calumpang', 'Concepcion Dos', 'Concepcion Uno',
      'Fortune', 'Industrial Valley', 'Jesus dela Peña', 'Kalumpang',
      'Malanday', 'Marikina Heights', 'Nangka', 'Parang', 'San Roque',
      'Santa Elena', 'Santo Niño', 'Tañong', 'Tumana',
    ]),
    PhCity(name: 'Muntinlupa', barangays: [
      'Alabang', 'Bayanan', 'Buli', 'Cupang', 'Poblacion', 'Putatan',
      'Sucat', 'Tunasan',
    ]),
    PhCity(name: 'Pasay', barangays: [
      'Bagong Pagasa', 'Barangay 76', 'Barangay 101', 'Barangay 183',
      'Don Bosco', 'Harrison', 'Libertad', 'Malibay', 'Maricaban', 'Quirino',
      'San Isidro', 'San Jose', 'San Rafael', 'Santo Niño', 'Tramo',
    ]),
    PhCity(name: 'San Juan', barangays: [
      'Addition Hills', 'Balong-Bato', 'Batis', 'Corazon de Jesus',
      'Ermitaño', 'Greenhills', 'Isabelita', 'Kabayanan', 'Little Baguio',
      'Maytunas', 'Onse', 'Pasadena', 'Pinaglabanan', 'Rivera', 'Salapan',
      'San Perfecto', 'Santa Lucia', 'Tibagan', 'West Crame',
    ]),
    PhCity(name: 'Valenzuela', barangays: [
      'Arkong Bato', 'Balangkas', 'Bignay', 'Bisig', 'Canumay East',
      'Canumay West', 'Coloong', 'Dalandanan', 'Gen. T. de Leon',
      'Isla', 'Lawang Bato', 'Lingunan', 'Mabolo', 'Malanday',
      'Malinta', 'Mapulang Lupa', 'Marulas', 'Maysan', 'Palasan',
      'Parada', 'Pasolo', 'Poblacion', 'Pulo', 'Punturin', 'Rincon',
      'Tagalag', 'Ugong',
    ]),
    PhCity(name: 'Malabon', barangays: [
      'Acacia', 'Baritan', 'Bayan-bayanan', 'Catmon', 'Dampalit',
      'Flores', 'Hulong Duhat', 'Ibaba', 'Longos', 'Maysilo',
      'Muzon', 'Nagkaisang Nayon', 'Niugan', 'Panghulo', 'Potrero',
      'San Agustin', 'Santolan', 'Tinajeros', 'Tonsuya', 'Tugatog',
    ]),
    PhCity(name: 'Navotas', barangays: [
      'Bagumbayan North', 'Bagumbayan South', 'Bangculasi', 'Daanghari',
      'Navotas East', 'Navotas West', 'North Bay Blvd. North',
      'North Bay Blvd. South', 'San Jose', 'San Rafael Village',
      'San Roque', 'Sipac-Almacen', 'Tangos North', 'Tangos South',
    ]),
  ]),

  // ── Region I – Ilocos Region ───────────────────────────────────────────────
  PhRegion(name: 'Region I – Ilocos Region', cities: [
    PhCity(name: 'Laoag City', barangays: [
      'Bacsil', 'Bengcag', 'Buttong', 'Caaoacan', 'Cavit', 'Nagbacalan',
      'Nstra. Sra. de Consolacion', 'Nstra. Sra. del Rosario',
      'Población 1–6', 'San Lorenzo', 'San Matias', 'San Miguel',
      'San Nicolas', 'San Silverio', 'Santa Joaquina', 'Suyo',
    ]),
    PhCity(name: 'Vigan City', barangays: [
      'Ayusan Norte', 'Ayusan Sur', 'Barangay I', 'Barangay II',
      'Barangay III', 'Barangay IV', 'Barangay V', 'Barangay VI',
      'Barangay VII', 'Barangay VIII', 'Barangay IX', 'Barangay X',
      'Mindoro', 'Paoa', 'Pantay Daya', 'Pantay Fatima',
      'Pantay Laud', 'Raois', 'Rid-Riding',
    ]),
    PhCity(name: 'San Fernando City (La Union)', barangays: [
      'Abut', 'Apaleng', 'Bacsil', 'Bangbangolan', 'Bangcusay',
      'Barangay I', 'Barangay II', 'Barangay III', 'Barangay IV', 'Cabaroan',
      'Cadaclan', 'Canaoay', 'Carlatan', 'Catbangen', 'Dallangayan Este',
      'Dallangayan Oeste', 'Dalumpinas Este', 'Dalumpinas Oeste',
      'Ilocanos Norte', 'Ilocanos Sur', 'Langcuas', 'Lingsat', 'Madayegdeg',
      'Mameltac', 'Masicong', 'Nagyubuyuban', 'Namtutan', 'Narra Este',
      'Narra Oeste', 'Pacpaco', 'Pagdalagan', 'Pagdaraoan', 'Pagudpud',
      'Pao Norte', 'Pao Sur', 'Parian', 'Poblacion', 'Resurreccion',
      'Sacpil', 'Sibangen', 'Tanqui', 'Tanquigan',
    ]),
    PhCity(name: 'Dagupan City', barangays: [
      'Bacayao Norte', 'Bacayao Sur', 'Barangay I', 'Barangay II',
      'Barangay III', 'Barangay IV', 'Bolosan', 'Bonuan Binloc',
      'Bonuan Boquig', 'Bonuan Gueset', 'Calmay', 'Carael', 'Caranglaan',
      'Herrero', 'Lasip Chico', 'Lasip Grande', 'Lomboy', 'Lucao',
      'Malued', 'Mamalingling', 'Mangin', 'Mayombo', 'Pantal',
      'Poblacion Oeste', 'Pogo Chico', 'Pogo Grande', 'Pugaro Suit',
      'Salapingao', 'Salisay', 'Tambac', 'Tapuac', 'Tebeng',
    ]),
  ]),

  // ── Region II – Cagayan Valley ─────────────────────────────────────────────
  PhRegion(name: 'Region II – Cagayan Valley', cities: [
    PhCity(name: 'Tuguegarao City', barangays: [
      'Annafunan East', 'Annafunan West', 'Atulayan Norte', 'Atulayan Sur',
      'Bagay', 'Buntun', 'Caggay', 'Capatan', 'Carig Sur', 'Caritan Centro',
      'Caritan Norte', 'Caritan Sur', 'Cataggaman Nuevo', 'Cataggaman Pardo',
      'Cataggaman Viejo', 'Cuguing', 'Gosi Norte', 'Gosi Sur', 'Larion Alto',
      'Larion Bajo', 'Leonarda', 'Libag Norte', 'Libag Sur', 'Linao East',
      'Linao Norte', 'Linao West', 'Namabbalan Norte', 'Namabbalan Sur',
      'Pallua Norte', 'Pallua Sur', 'Pengue Ruyu', 'Poblacion', 'Reyes',
      'San Gabriel', 'Tagga', 'Tanza', 'Ugac Norte', 'Ugac Sur',
    ]),
    PhCity(name: 'Cauayan City', barangays: [
      'Alicaocao', 'Alinam', 'Amobocan', 'Andarayan', 'Baculod', 'Baringin Norte',
      'Baringin Sur', 'Bugatay', 'Burgos', 'Cabaruan', 'Cabugao', 'Calaw',
      'Callao', 'Calaoagan', 'Caunayan', 'Divisoria Norte', 'Divisoria Sur',
      'Duminit', 'Faustino', 'Gagabutan', 'Gatarano', 'Iguig', 'Lamu',
      'Lubnac', 'Mabantad', 'Malasin', 'Malitao', 'Manaoag', 'Masigun',
      'Minante Primero', 'Minante Segundo', 'Nagcampegan', 'Naganacan',
      'Nagrumbuan', 'Nungnungan Primero', 'Nungnungan Segundo', 'Pinoma',
      'Población Norte', 'Población Sur', 'Quezon', 'Quirino', 'Ragan Norte',
      'Ragan Sur', 'Reyes', 'Rogus', 'San Antonio', 'San Carlos',
      'San Fermin', 'San Luis', 'San Pablo', 'Santa Lucía', 'Santa Maria',
      'Sarrat', 'Sinabbaran', 'Soyung',
    ]),
  ]),

  // ── Region III – Central Luzon ─────────────────────────────────────────────
  PhRegion(name: 'Region III – Central Luzon', cities: [
    PhCity(name: 'Angeles City', barangays: [
      'Agapito del Rosario', 'Amsic', 'Anunas', 'Balibago', 'Capaya',
      'Claro M. Recto', 'Cuayan', 'Cutcut', 'Cutud', 'Lourdes Norte',
      'Lourdes Sur', 'Lourdes Sur East', 'Malabanias', 'Malabañas',
      'Margot', 'Ninoy Aquino', 'Pampang', 'Pandan', 'Pulung Cacutud',
      'Pulung Maragul', 'Salapungan', 'San Jose', 'San Nicolas', 'Santa Teresita',
      'Santa Trinidad', 'Santo Cristo', 'Santo Domingo', 'Santo Rosario',
      'Sapangbato', 'Tabun', 'Virgen Delos Remedios',
    ]),
    PhCity(name: 'San Fernando City (Pampanga)', barangays: [
      'Alasas', 'Baliti', 'Bulaon', 'Calulut', 'Del Carmen', 'Del Pilar',
      'Del Rosario', 'Dolores', 'Juliana', 'Lara', 'Lourdes', 'Magliman',
      'Maimpis', 'Malino', 'Malpitic', 'Pandaras', 'Panipuan', 'Pulung Bulo',
      'Quebiawan', 'Saguin', 'San Agustin', 'San Felipe', 'San Isidro',
      'San Jose', 'San Juan', 'San Nicolas', 'San Pedro', 'Santa Lucia',
      'Santa Teresita', 'Santo Niño', 'Santo Rosario', 'Sindalan',
      'Telabastagan',
    ]),
    PhCity(name: 'Olongapo City', barangays: [
      'Asinan', 'Bajac-Bajac', 'Balagtas', 'Barretto', 'East Bajac-Bajac',
      'Gordon Heights', 'Kalaklan', 'Mabayuan', 'New Cabalan', 'New Ilalim',
      'New Kababae', 'New Kalalake', 'Old Cabalan', 'Pag-asa', 'Santa Rita',
      'West Tapinac',
    ]),
    PhCity(name: 'Malolos City', barangays: [
      'Anilao', 'Atlag', 'Babatnin', 'Bagna', 'Bagumbayan', 'Balayong',
      'Balite', 'Bangkal', 'Barihan', 'Bulihan', 'Bungahan', 'Camalandaan',
      'Camias', 'Caniogan', 'Catmon', 'Cofradia', 'Dakila', 'Guinhawa',
      'Ligas', 'Liyang', 'Longos', 'Look 1st', 'Look 2nd', 'Lugam',
      'Mabolo', 'Malusak', 'Masagana', 'Masaguing', 'Matatalaib',
      'Matimbo', 'Mojon', 'Namayan', 'Niugan', 'Pamarawan', 'Panasahan',
      'Pinagbakahan', 'San Agustin', 'San Gabriel', 'San Jose', 'San Juan',
      'San Pablo', 'San Vicente', 'Santa Clara', 'Santa Cruz', 'Santa Isabel',
      'Santiago', 'Santisima Trinidad', 'Santo Cristo', 'Santo Niño',
      'Santo Rosario', 'Santol', 'Sumapang Bata', 'Sumapang Matanda',
      'Taal', 'Tikay',
    ]),
  ]),

  // ── Region IV-A – CALABARZON ──────────────────────────────────────────────
  PhRegion(name: 'Region IV-A – CALABARZON', cities: [
    PhCity(name: 'Antipolo City', barangays: [
      'Bagong Nayon', 'Beverly Hills', 'Calawis', 'Carosariohan', 'Cupang',
      'Dalig', 'Del Rosario', 'Inarawan', 'Mambugan', 'Mayamot', 'Muntingdilaw',
      'San Jose', 'San Juan', 'San Luis', 'San Roque', 'Santa Cruz',
      'Sitio Montaña',
    ]),
    PhCity(name: 'Batangas City', barangays: [
      'Alangilan', 'Arce Subdivision', 'Arrieta', 'Bañadero', 'Bungoy',
      'Calicanto', 'Cuta', 'Dalig', 'Dela Paz', 'Dumantay',
      'Gulod Labac', 'Gulod Itaas', 'Libjo', 'Maapaz', 'Mabacong',
      'Malibayo', 'Maliksi', 'Manlupig', 'Mansanggaya', 'Pagkilatan',
      'Pallocan East', 'Pallocan West', 'Pinamucan East', 'Pinamucan Ibaba',
      'Pinamucan West', 'Poblacion', 'Sampaga', 'San Agapito',
      'San Agustin East', 'San Agustin West', 'San Andres', 'San Antonio',
      'San Isidro', 'Santa Clara', 'Santa Rita Aplaya', 'Santa Rita Karsada',
      'Santo Domingo', 'Santo Niño', 'Santo Tomas', 'Simlong',
      'Sorosoro Ibaba', 'Sorosoro Ilaya', 'Tabangao', 'Tingrejas',
      'Wawa',
    ]),
    PhCity(name: 'Calamba City', barangays: [
      'Bagong Kalsada', 'Banadero', 'Banlic', 'Barandal', 'Brgy. Uno',
      'Bucal', 'Burol', 'Camaligan', 'Canlubang', 'Halang',
      'Hornalan', 'Kay-Anlog', 'La Mesa', 'Laguerta', 'Lawa',
      'Lecheria', 'Lingga', 'Looc', 'Mabato', 'Makiling',
      'Majada Out', 'Mapagong', 'Masili', 'Maunong', 'Mayapa',
      'Milagrosa (Palayan)', 'Paciano Rizal', 'Palingon', 'Palo Alto',
      'Pansol', 'Parian', 'Prinza', 'Pulo', 'Putho Tuntungin',
      'Real', 'Sucol', 'Turbina', 'Ulango', 'Uwisan',
    ]),
    PhCity(name: 'Lucena City', barangays: [
      'Barangay 1', 'Barangay 2', 'Barangay 3', 'Barangay 4', 'Barangay 5',
      'Barangay 6', 'Barangay 7', 'Barangay 8', 'Barangay 9', 'Barangay 10',
      'Barangay I', 'Barangay II', 'Barangay III', 'Barangay IV',
      'Barangay V', 'Barangay VI', 'Barangay VII', 'Barangay VIII',
      'Barangay IX', 'Barangay X', 'Ibabang Dupay', 'Ibabang Iyam',
      'Ibabang Talim', 'Ilayang Dupay', 'Ilayang Talim', 'Isabang',
      'Market Area', 'Mayao Castillo', 'Mayao Crossing', 'Mayao Kanluran',
      'Mayao Parada', 'Mayao Silangan',
    ]),
  ]),

  // ── Region IV-B – MIMAROPA ────────────────────────────────────────────────
  PhRegion(name: 'Region IV-B – MIMAROPA', cities: [
    PhCity(name: 'Puerto Princesa City', barangays: [
      'Bagong Bayan', 'Bagong Silang', 'Bacungan', 'Baliwasan', 'Binduyan',
      'Buenavista', 'Cabayugan', 'Concepcion', 'Inagawan', 'Irawan',
      'Langogan', 'Lucbuan', 'Luzviminda', 'Macarascas', 'Marufinas',
      'Maruyogon', 'Matiyaga', 'Milibo', 'Montible', 'Napsan',
      'New Panggangan', 'Princesa', 'Salvacion', 'San Jose',
      'San Manuel', 'San Miguel', 'San Pedro', 'San Rafael', 'Santa Lourdes',
      'Santa Lucia', 'Santo Niño', 'Sicsican', 'Tagburos', 'Tagumpay',
      'Tiniguiban',
    ]),
  ]),

  // ── Region V – Bicol Region ────────────────────────────────────────────────
  PhRegion(name: 'Region V – Bicol Region', cities: [
    PhCity(name: 'Naga City', barangays: [
      'Abella', 'Bagumbayan Norte', 'Bagumbayan Sur', 'Balatas', 'Calauag',
      'Cararayan', 'Carolina', 'Concepcion Pequeña', 'Dinaga', 'Igualdad Interior',
      'Lerma', 'Liboton', 'Mabolo', 'Pacol', 'Panicuason', 'Penafrancia',
      'Sabang', 'San Felipe', 'San Francisco', 'San Isidro', 'Santa Cruz',
      'Tabuco', 'Tinago', 'Triangulo',
    ]),
    PhCity(name: 'Legazpi City', barangays: [
      'Arimbay', 'Bagacay', 'Banquerohan', 'Barangay 1–20 (Poblacion)',
      'Bigaa', 'Binanuahan East', 'Binanuahan West', 'Buyuan', 'Cabangan',
      'Cagbacong', 'Dita', 'Estanza', 'Gogon', 'Homapon', 'Imperial Court Subd.',
      'Imalnod', 'Kapantawan', 'Kilikao', 'Kumalarang', 'Landco',
      'Laniton', 'Layog', 'Linao', 'Mabinit', 'Mariawa', 'Maslog',
      'Maoyod', 'Naga (Rizal)', 'Old Albay', 'Pag-Asa', 'Pawa',
      'Rawis', 'Sagpon', 'Salvacion', 'San Francisco', 'San Joaquin',
      'San Roque', 'Tamaoyan', 'Taysan', 'Tinago', 'Tiwi',
    ]),
  ]),

  // ── Region VI – Western Visayas ────────────────────────────────────────────
  PhRegion(name: 'Region VI – Western Visayas', cities: [
    PhCity(name: 'Iloilo City', barangays: [
      'Agdao', 'Balabag', 'Balantang', 'Bo. Obrero', 'Bakhaw', 'Benedicto',
      'Bolilao', 'Buenavista', 'Buntatala', 'Calaparan', 'Calumpang',
      'Compañia', 'Democracia', 'East Baluarte', 'East Timawa', 'Edganzon',
      'Infanta', 'Jalandoni Estate', 'Jayme', 'Kahirup', 'Lanot', 'Lapuz Norte',
      'Lapuz Sur', 'Layac', 'Leganes', 'Libertad', 'Loboc', 'LogLog',
      'Lonoy', 'Lopez Jaena Norte', 'Lopez Jaena Sur', 'Mabolo',
      'Malipayon-Delgado', 'Maria Clara', 'Montinola', 'Muelle Loney',
      'Nabitasan', 'North Baluarte', 'North Signal', 'Oñate de Leon',
      'Pale Benedicto', 'Palapala', 'Pale Calumpang', 'Pale Nabitasan',
      'Pale Progreso', 'Pale Q. Abeto', 'Progreso', 'Q. Abeto (Lapu-Lapu)',
      'Quintin Salas', 'Rizal Palapala', 'Rizal Poblacion', 'San Isidro',
      'San Jose', 'San Juan', 'San Nicolas', 'Santa Filomena',
      'Santiago', 'Santo Niño Norte', 'Santo Niño Sur', 'Santo Rosario',
      'Seminario', 'Simon Ledesma', 'Sooc', 'Taal', 'Tabuc Suba',
      'Taytay', 'Ticud', 'Timawa Tanza', 'Ungka',
    ]),
    PhCity(name: 'Bacolod City', barangays: [
      'Alangilan', 'Alijis', 'Banago', 'Bata', 'Cabug', 'Estefania', 'Felisa',
      'Granada', 'Handumanan', 'Lag-asan', 'Mandalagan', 'Mansilingan',
      'Montevista', 'Pahanocoy', 'Punta Taytay', 'Singcang-Airport',
      'Sum-ag', 'Taculing', 'Tangub', 'Villamonte', 'Vista Alegre',
    ]),
  ]),

  // ── Region VII – Central Visayas ───────────────────────────────────────────
  PhRegion(name: 'Region VII – Central Visayas', cities: [
    PhCity(name: 'Cebu City', barangays: [
      'Adlaon', 'Agsungot', 'Apas', 'Babag', 'Bacayan', 'Banilad',
      'Basak Pardo', 'Basak San Nicolas', 'Binaliw', 'Bonbon', 'Budlaan',
      'Busay', 'Calamba', 'Cambinocot', 'Capitol Site', 'Carreta',
      'Central', 'Cogon Pardo', 'Cogon Ramos', 'Day-as', 'Duljo',
      'Ermita', 'Guadalupe', 'Guba', 'Hipodromo', 'Inayawan', 'Kalubihan',
      'Kalunasan', 'Kamagayan', 'Kasambagan', 'Kinasang-an', 'Labangon',
      'Lahug', 'Lorega (Lorega San Miguel)', 'Lusaran', 'Luz',
      'Mabini', 'Mabolo', 'Malubog', 'Mambaling', 'Pahina Central',
      'Pahina San Nicolas', 'Pamutan', 'Pari-an', 'Paril', 'Pasil',
      'Pit-os', 'Poblacion Pardo', 'Pulangbato', 'Pung-ol-Sibugay',
      'Punta Princesa', 'Quiot Pardo', 'Sambag I', 'Sambag II',
      'San Antonio', 'San Jose', 'San Nicolas Central', 'San Nicolas Proper',
      'San Roque (Ciudad)', 'Santo Niño', 'Sapangdaku', 'Sawang Calero',
      'Sinsin', 'Sirao', 'Suba (Suba San Nicolas)', 'Sudlon I',
      'Sudlon II', 'T. Padilla', 'Tabunan', 'Tagba-o', 'Talamban',
      'Taptap', 'Tejero (Villa Gonzalo)', 'Tinago', 'Tisa',
      'To-ong Pardo', 'Zapatera',
    ]),
    PhCity(name: 'Lapu-Lapu City', barangays: [
      'Agus', 'Babag', 'Bankal', 'Baring', 'Basak', 'Buaya',
      'Calawisan', 'Canjulao', 'Caubian', 'Caw-oy', 'Cawhagan',
      'Gun-ob', 'Ibo', 'Looc', 'Mactan', 'Maribago', 'Marigondon',
      'Pajac', 'Pajo', 'Pangan-an', 'Poblacion', 'Puco', 'Pusok',
      'Sabang', 'Santa Rosa', 'Subabasbas', 'Talima', 'Tingo',
      'Tungasan',
    ]),
    PhCity(name: 'Mandaue City', barangays: [
      'Alang-alang', 'Banilad', 'Bakilid', 'Basak', 'Canduman',
      'Casili', 'Casuntingan', 'Centro (Poblacion)', 'Cubacub',
      'Guizo', 'Ibabao-Estancia', 'Jagobiao', 'Labogon', 'Looc',
      'Maguikay', 'Mahayahay', 'Mantuyong', 'Opao', 'Pakna-an',
      'Paknaan', 'Subangdaku', 'Tabok', 'Tawason', 'Tingub', 'Tipolo',
      'Umapad',
    ]),
    PhCity(name: 'Dumaguete City', barangays: [
      'Bagacay', 'Bajumpandan', 'Banilad', 'Bantayan', 'Barrio Camanjac',
      'Barrio Looc', 'Barrio Mabato', 'Barrio Piapi', 'Barrio Tinago',
      'Cadawinonan', 'Calindagan', 'Camanjac', 'Candau-ay', 'Cantil-e',
      'Cawitan', 'Daro', 'Junob', 'Kagawasan', 'Looc', 'Mabato',
      'Mangnao-Canal', 'Motong', 'Piapi', 'Poblacion No. 1',
      'Poblacion No. 2', 'Poblacion No. 3', 'Poblacion No. 4',
      'Poblacion No. 5', 'Poblacion No. 6', 'Poblacion No. 7',
      'Poblacion No. 8', 'Sambuan', 'Taclobo', 'Tinago',
    ]),
  ]),

  // ── Region VIII – Eastern Visayas ──────────────────────────────────────────
  PhRegion(name: 'Region VIII – Eastern Visayas', cities: [
    PhCity(name: 'Tacloban City', barangays: [
      'Anibong', 'Bagacay', 'Barangay 100 (Abucay)', 'Barangay 105',
      'Barangay 109', 'Barangay 110', 'Barangay 36–40', 'Barangay 41–50',
      'Barangay 51–60', 'Barangay 61–70', 'Barangay 71–80', 'Barangay 81–90',
      'Barangay 91–99', 'Cabalawan', 'Caibaan', 'Calanipawan',
      'Campetic', 'Carayman', 'City Central', 'Diit', 'Fatima',
      'Hapay', 'Kawayan Tres', 'Kawayan Uno', 'Libertad', 'Marasbaras',
      'New Kawayan', 'Nula-tula', 'Palanog', 'Pampango', 'Pio Abella',
      'Salvacion', 'San Jose (Tagpuro)', 'Santo Niño', 'Suhi',
      'Tagpuro', 'Tigbao', 'V & G Subd.', 'Vladia',
    ]),
  ]),

  // ── Region IX – Zamboanga Peninsula ───────────────────────────────────────
  PhRegion(name: 'Region IX – Zamboanga Peninsula', cities: [
    PhCity(name: 'Zamboanga City', barangays: [
      'Arena Blanco', 'Ayala', 'Baliwasan', 'Baluno', 'Boalan',
      'Bolong', 'Buenavista', 'Bunguiao', 'Busay (Sacol Island)',
      'Cabaluay', 'Cabatangan', 'Cacao', 'Calabasa', 'Calarian',
      'Camino Nuevo', 'Canelar', 'Capisan', 'Cawit', 'Culianan',
      'Curuan', 'Dita', 'Don Héctor Galvez', 'Divisoria',
      'Dulian (Dulian Upper)', 'Dulangan', 'Guiwan', 'Kasanyangan',
      'La Paz', 'Labuan', 'Lamisahan', 'Landang Gua', 'Landang Laum',
      'Lanzones', 'Lapakan', 'Latuan (Calugusan)', 'Licomo',
      'Limaong', 'Limpapa', 'Lubigan', 'Lumayang', 'Lumbangan',
      'Lunzuran', 'Maasin', 'Malagutay', 'Mampang', 'Manalipa',
      'Mangusu', 'Manicahan', 'Mapuso', 'Mariki', 'Mercedes',
      'Muti', 'Pamucutan', 'Pangapuyan', 'Panubigan', 'Pasilmanta',
      'Pasobolong', 'Patalon', 'Putik', 'Quiniput', 'Recodo',
      'Rio Hondo', 'Salunayan', 'San José Cawa-cawa', 'San José Gusu',
      'San Roque', 'Sangali', 'Santa Barbara', 'Santa Catalina',
      'Santa Maria', 'Sibulao (Caruan)', 'Sinubung', 'Sinunoc',
      'Tagasilay', 'Taguiti', 'Talabaan', 'Talisayan', 'Talon-Talon',
      'Tambacan', 'Tambuli', 'Tictapul', 'Tigbalabag', 'Tomas Claudio',
      'Tugbungan', 'Tulungatung', 'Tumaga', 'Tumalutab', 'Tumulak',
      'Ubojan', 'Vitali', 'Waling-waling', 'Yacapin',
    ]),
  ]),

  // ── Region X – Northern Mindanao ───────────────────────────────────────────
  PhRegion(name: 'Region X – Northern Mindanao', cities: [
    PhCity(name: 'Cagayan de Oro City', barangays: [
      'Agusan', 'Baikingon', 'Balubal', 'Balulang', 'Bayabas',
      'Besigan', 'Bonbon', 'Bugo', 'Bulua', 'Canitoan',
      'Cugman', 'Dansolihon', 'F.S. Catanico', 'Gusa',
      'Indahag', 'Iponan', 'Kauswagan', 'Lapasan', 'Lumbia',
      'Macabalan', 'Macasandig', 'Mambuaya', 'Nazareth', 'Pagalungan',
      'Pagatpat', 'Patag', 'Pigsag-an', 'Puerto', 'Puntod',
      'Rosario', 'Tablon', 'Taglimao', 'Tagpangi', 'Tignapoloan',
      'Tumpagon', 'Upper Balulang', 'Ves',
    ]),
    PhCity(name: 'Iligan City', barangays: [
      'Abuno', 'Acmac-Mariano Badelles Sr.', 'Bagong Silang', 'Buru-un',
      'Dalipuga', 'Del Carmen', 'Digkilaan', 'Ditucalan', 'Dulag',
      'Hinaplanon', 'Hindang', 'Kabacsanan', 'Kalilangan', 'Kiwalan',
      'Lanipao', 'Luinab', 'Mahayahay', 'Mainit', 'Mandulog',
      'Maria Cristina', 'Palao', 'Panoroganan', 'Poblacion', 'Puga-an',
      'Rogongon', 'San Miguel', 'San Roque', 'Santa Elena',
      'Santa Filomena', 'Santiago', 'Santo Rosario', 'Saray',
      'Suarez', 'Tambacan', 'Tibanga', 'Tipanoy', 'Tominobo Proper',
      'Tominobo Upper', 'Tubod', 'Ubaldo Laya', 'Upper Hinaplanon',
      'Upper Tominobo', 'Villaverde',
    ]),
  ]),

  // ── Region XI – Davao Region ───────────────────────────────────────────────
  PhRegion(name: 'Region XI – Davao Region', cities: [
    PhCity(name: 'Davao City', barangays: [
      'Acacia', 'Agdao', 'Alambre', 'Alejandra Navarro (Lasang)', 'Alfonso Angliongto Sr.',
      'Angalan', 'Atan-Awe', 'Baganihan', 'Bago Aplaya', 'Bago Gallera',
      'Bago Oshiro', 'Baguio', 'Balengaeng', 'Baliok', 'Bangkas Heights',
      'Bantol', 'Baracatan', 'Barangay 1–40 (Poblacion)', 'Biao Escuela',
      'Biao Guianga', 'Biao Joaquin', 'Binugao', 'Buda', 'Buhangin',
      'Bunawan', 'Busaon', 'Cabantian', 'Cadalian', 'Calinan',
      'Camudmud', 'Carmen', 'Catalunan Grande', 'Catalunan Pequeño',
      'Catigan', 'Cayanan', 'Centro (San Juan)', 'Colosas',
      'Communal', 'Crossing Bayabas', 'Dacudao', 'Dalag',
      'Dalagdag', 'Daliaon Plantation', 'Datu Salumay', 'Dominga',
      'Dumoy', 'Eden', 'Fatima', 'Gatungan', 'Gov. Paciano Bangoy',
      'Gov. Vicente Duterte', 'Gumalang', 'Ilang', 'Indangan',
      'Kap. Tomas Monteverde Sr.', 'Lacson', 'Lamanan', 'Lampianao',
      'Langub', 'Lapu-lapu', 'Leon Garcia', 'Liberty', 'Lizada',
      'Los Amigos', 'Lubogan', 'Lumiad', 'Ma-a', 'Mabuhay',
      'Malagos', 'Malamba', 'Manambulan', 'Mandug', 'Manuel Guianga',
      'Mapula', 'Marapangi', 'Marilog', 'Matina Aplaya', 'Matina Crossing',
      'Matina Pangi', 'Megkawayan', 'Mintal', 'Mudiang', 'Mulig',
      'New Carmen', 'New Valencia', 'Pampanga', 'Pañabo',
      'Paquibato', 'Paradise Embak', 'Riverside', 'Sagunayan',
      'Salapawan', 'Salaysay', 'Saloy', 'San Antonio', 'San Isidro',
      'Sangay', 'Santo Niño', 'Sasa', 'Sibulan', 'Sirawan',
      'Sirib', 'Subasta', 'Sumimao', 'Tacunan', 'Tagakpan',
      'Tagluno', 'Tagurano', 'Talomo', 'Tamayong', 'Tamugan',
      'Tapak', 'Tawan-tawan', 'Tibuloy', 'Tibungco', 'Tigatto',
      'Toril', 'Tugbok', 'Tungkalan', 'Ubalde', 'Uian',
      'United Heights', 'Ulas', 'Vicente Hizon Sr.', 'Waan',
      'Wangan', 'Wilfredo Aquino', 'Wines',
    ]),
    PhCity(name: 'General Santos City', barangays: [
      'Apopong', 'Baluan', 'Batomelong', 'Buayan', 'Bula', 'Calumpang',
      'City Heights', 'Conel', 'Dadiangas East', 'Dadiangas North',
      'Dadiangas South', 'Dadiangas West', 'Fatima', 'Katangawan',
      'Labangal', 'Lagao', 'Ligaya', 'Mabuhay', 'Olympog',
      'San Isidro', 'San Jose', 'Sinawal', 'Tambler', 'Tinagacan',
      'Upper Labay',
    ]),
  ]),

  // ── Region XII – SOCCSKSARGEN ──────────────────────────────────────────────
  PhRegion(name: 'Region XII – SOCCSKSARGEN', cities: [
    PhCity(name: 'Cotabato City', barangays: [
      'Bagua I', 'Bagua II', 'Bagua III', 'Kalanganan I', 'Kalanganan II',
      'Poblacion I', 'Poblacion II', 'Poblacion III', 'Poblacion IV',
      'Poblacion V', 'Poblacion VI', 'Poblacion VII', 'Poblacion VIII',
      'Poblacion IX', 'Rosary Heights I', 'Rosary Heights II',
      'Rosary Heights III', 'Rosary Heights IV', 'Rosary Heights V',
      'Rosary Heights VI', 'Rosary Heights VII', 'Rosary Heights VIII',
      'Rosary Heights IX', 'Rosary Heights X', 'Rosary Heights XI',
      'Tamontaka I', 'Tamontaka II', 'Tamontaka III', 'Tamontaka IV',
      'Tamontaka V',
    ]),
  ]),

  // ── Region XIII – Caraga ───────────────────────────────────────────────────
  PhRegion(name: 'Region XIII – Caraga', cities: [
    PhCity(name: 'Butuan City', barangays: [
      'Agao', 'Agusan Pequeño', 'Ambago', 'Amparo', 'Ampayon', 'Anticala',
      'Antongalon', 'Aupagan', 'Baan KM 3', 'Baan Riverside', 'Babag',
      'Bading', 'Bancasi', 'Banza', 'Bao', 'Basag', 'Bayanihan',
      'Bilay', 'Bit-os', 'Bitan-agan', 'Bobon', 'Bonbon', 'Bugabus',
      'Bugsukan', 'Buhangin', 'Cabcabon', 'Camayahan', 'Dagohoy',
      'Dankias', 'De Oro', 'Don Francisco', 'Doongan', 'Dumalagan',
      'Florida', 'Imadejas (Imadelas)', 'Langihan', 'Libertad',
      'Limaha', 'Los Angeles', 'Lumbocan', 'Maguinda', 'Mahay',
      'Mahayahay', 'Maibu', 'Mandamo', 'Manila de Bugabus',
      'Maon', 'Masao', 'Maug', 'Mogcop', 'Nong-nong',
      'Nueva Era', 'Obrero', 'Ong Yiu', 'Pagatpatan',
      'Pangabugan', 'Pianing', 'Pigdaulan', 'Pinamanculan',
      'Port Area', 'Rizal', 'Salvacion', 'San Ignacio', 'San Mateo',
      'San Vicente', 'Sikatuna', 'Silongan', 'Sumilihon',
      'Tagabaca', 'Taguibo', 'Taligaman', 'Taloto', 'Tapat',
      'Tiniwisan', 'Tungao', 'Urduja',
    ]),
  ]),

  // ── CAR – Cordillera Administrative Region ─────────────────────────────────
  PhRegion(name: 'CAR – Cordillera Administrative Region', cities: [
    PhCity(name: 'Baguio City', barangays: [
      'Abanao-Zandueta-Kayong-Chugum-Otek', 'Alfonso Tabora', 'Ambiong',
      'Andres Bonifacio', 'Apugan-Loakan', 'Asin Road', 'Atab',
      'Aurora Hill Proper', 'Aurora Hill North Central', 'Bagong Lipunan',
      'Bakakeng Central', 'Bakakeng Norte', 'Balsigan', 'Bayan Park East',
      'Bayan Park West', 'BGH Compound', 'Brookside', 'Buol',
      'Cabinet Hill-Teacher\'s Camp', 'Camp 7', 'Camp 8', 'Camp Allen',
      'Carbonero', 'City Camp Central', 'City Camp Lagoon', 'Dagsian Upper',
      'Dominican Hill-Mirador', 'Dontogan', 'DPS Area', 'Dry Market',
      'Englizon', 'Fairview Village', 'Ferdinand (Lower Magsaysay)',
      'Fort del Pilar', 'Gabriela Silang', 'General Luna Road',
      'Gibraltar', 'Greenwater Village', 'Guisad Central', 'Guisad Sorong',
      'Harrison-Clario', 'Hillside', 'Holyghost Extension', 'Holyghost Proper',
      'Imelda R. Marcos', 'Irisan', 'Kayang Extension', 'Kayang-Hilltop',
      'Kias', 'Legarda-Burnham-Kisad', 'Loakan Proper', 'Lopez Jaena',
      'Lourdes Subdivision Extension', 'Lourdes Subdivision Proper',
      'Lower Dagsian', 'Lower General Luna Road', 'Lower Magsaysay',
      'Lower Rock Quarry', 'Magsaysay Private Road', 'Malcolm Square',
      'Manual', 'Marikina', 'Middle Quezon Hill', 'Military Cut-off',
      'Mines View Park', 'Modern Site East', 'Modern Site West',
      'MRR-Queen of Peace', 'New Lucban', 'Outlook Drive', 'Pacdal',
      'Padre Burgos', 'Padre Zamora', 'Palma-Urbano', 'Phil. Rabbit',
      'Pinget', 'Pinsao Pilot Project', 'Pinsao Proper', 'Poliwes',
      'Pucsusan', 'Quezon Hill Proper', 'Quezon Hill Upper',
      'Rock Quarry Lower', 'Rock Quarry Middle', 'Rock Quarry Upper',
      'Sacred Heart Village', 'Salud Mitra', 'San Antonio Village',
      'San Luis Village', 'San Roque Village', 'Santa Escolastica',
      'Santo Rosario', 'Santo Tomas', 'Scout Barrio', 'Session Road Area',
      'Slaughterhouse Area', 'South Drive', 'Teodora Alonzo', 'Trancoville',
      'Upper Market Subdivision', 'Victoria Village',
    ]),
    PhCity(name: 'Tabuk City', barangays: [
      'Agbannawag', 'Amlao', 'Bagumbayan', 'Bulanao Norte', 'Bulanao Sur',
      'Bulo', 'Calaocan', 'Casigayan', 'Cudal', 'Dagupan Este',
      'Dagupan Weste', 'Dilag', 'Dupag', 'Gobgob', 'Guilayon',
      'Ikukan', 'Ipil', 'Lanna', 'Liwan East', 'Liwan West',
      'Lucog', 'Magsilay', 'Manarang', 'Nambaran', 'Nasiplatan',
      'Poblacion East', 'Poblacion West', 'Pugong', 'Quinawegan',
      'Ripang', 'San Antonio', 'San Juan', 'San Marcos',
      'San Pedro', 'Socbot', 'Tanglag', 'Tuga',
    ]),
  ]),

  // ── BARMM – Bangsamoro Autonomous Region in Muslim Mindanao ───────────────
  PhRegion(name: 'BARMM – Bangsamoro Region', cities: [
    PhCity(name: 'Marawi City', barangays: [
      'Amito Marantao', 'Bacolod Chico Proper', 'Bangon', 'Basak Malutlut',
      'Beyaba-Damag', 'Bito Buadi Itowa', 'Bito Buadi Parba', 'Boganga',
      'Boto Ambolong', 'Bubong Madanding', 'Cadayonan', 'Daguduban',
      'Dansalan', 'Datu Naga', 'Dulay', 'Dulay West', 'East Basak',
      'Emie Punud', 'Fort', 'Gadongan', 'Gadongan Mapantao',
      'Guimba', 'Kapantaran', 'Kilala', 'Kormatan Matampay',
      'Lilod Maday', 'Lilod Saduc', 'Linao', 'Lomidong', 'Lumbac Marinaut',
      'Lumbaca Madaya', 'Lumbaca Toros', 'Malimono', 'Mapantao',
      'Marantao Proper', 'Marinaut East', 'Marinaut West', 'Matampay',
      'Matampay Ilidan', 'Mongayan', 'Moncado Colony', 'Moncado Kadingilan',
      'Moriatao-Sarip Alawi', 'Muadi', 'Nangca-an', 'Narra', 'Norhaya Village',
      'Olawa', 'Panggao Saduc', 'Pantaon', 'Papandayan', 'Paridi',
      'Poblacion', 'Rapasun MSU', 'Raya Madamba', 'Raya Ragayan',
      'Rorogagus East', 'Rorogagus Proper', 'Sabala Manao',
      'Saduc Proper', 'Sagonayan', 'Somiorang', 'South Bacolod',
      'Tampilong', 'Tomarompong', 'Tongantongan-Tuca Timbangalan',
      'Tuca Marinaut', 'Wawalayan Calocan', 'Wawalayan Marawi',
    ]),
  ]),
];
