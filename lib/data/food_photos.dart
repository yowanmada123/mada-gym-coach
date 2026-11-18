// Foto masakan dari Wikimedia Commons (lisensi tercantum per foto).
// Dikumpulkan via Commons API; URL = thumbnail lebar 640px.

class PhotoCredit {
  const PhotoCredit(this.url, this.title, this.author, this.license);
  final String url;
  final String title;
  final String author;
  final String license;
}

const Map<String, PhotoCredit> kDishPhotos = {
  'ayam_bakar': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/78/Ayam_bakar.jpg/960px-Ayam_bakar.jpg',
    'Ayam bakar.jpg',
    'Nisa usrifatul',
    'CC BY-SA 4.0',
  ),
  'beef_broccoli': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/86/Beef_and_broccoli_stir_fry_closeup.jpg/960px-Beef_and_broccoli_stir_fry_closeup.jpg',
    'Beef and broccoli stir fry closeup.jpg',
    'Joy',
    'CC BY 2.0',
  ),
  'buah_naga': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/23/Dragon_fruit_cut_by_Shyamal%282%29.jpg/960px-Dragon_fruit_cut_by_Shyamal%282%29.jpg',
    'Dragon fruit cut by Shyamal(2).jpg',
    'Shyamal Kumar Chaudhary',
    'CC BY-SA 4.0',
  ),
  'bubur_ayam': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/47/Bubur_Ayam_Cianjur.jpg/960px-Bubur_Ayam_Cianjur.jpg',
    'Bubur Ayam Cianjur.jpg',
    'Supardisahabu',
    'CC BY-SA 4.0',
  ),
  'capcay': PhotoCredit(
    'https://upload.wikimedia.org/wikipedia/commons/1/13/Cap_Cai.JPG',
    'Cap Cai.JPG',
    '2009-07-07',
    'CC BY-SA 3.0',
  ),
  'edamame': PhotoCredit(
    'https://upload.wikimedia.org/wikipedia/commons/8/87/Edamame_on_a_bamboo_bowl_by_yomi955.jpg',
    'Edamame on a bamboo bowl by yomi955.jpg',
    'yomi955',
    'CC BY 2.0',
  ),
  'gado_gado': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/30/Gado-gado_in_Jakarta.JPG/960px-Gado-gado_in_Jakarta.JPG',
    'Gado-gado in Jakarta.JPG',
    'Sakurai Midori',
    'CC BY 3.0',
  ),
  'grilled_chicken_salad': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e3/Liat_Portal_for_Foodie_Disorder_-_Homemade_grilled_chicken_thighs_with_rice_and_Israeli_salad.jpg/960px-Liat_Portal_for_Foodie_Disorder_-_Homemade_grilled_chicken_thighs_with_rice_and_Israeli_salad.jpg',
    'Liat Portal for Foodie Disorder - Homemade grilled chicken thighs with rice and Israeli salad.jpg',
    'HaJunkiyada',
    'CC BY-SA 4.0',
  ),
  'healthy_plate': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c6/Liat_Portal_for_Foodie_Disorder_-_Home_cooked_healthy_meal.jpg/960px-Liat_Portal_for_Foodie_Disorder_-_Home_cooked_healthy_meal.jpg',
    'Liat Portal for Foodie Disorder - Home cooked healthy meal.jpg',
    'HaJunkiyada',
    'CC BY-SA 4.0',
  ),
  'ikan_bakar': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/ec/Gurame_bakar_kecap_2.JPG/960px-Gurame_bakar_kecap_2.JPG',
    'Gurame bakar kecap 2.JPG',
    'Gunawan Kartapranata',
    'CC BY-SA 4.0',
  ),
  'infused_water': PhotoCredit(
    'https://upload.wikimedia.org/wikipedia/commons/b/b4/Penyajian_Infused_Water.jpg',
    'Penyajian Infused Water.jpg',
    'Ayana putri',
    'CC BY-SA 4.0',
  ),
  'jagung_rebus': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/71/Boiled_corn_on_a_white_plate.jpg/960px-Boiled_corn_on_a_white_plate.jpg',
    'Boiled corn on a white plate.jpg',
    'TudorTulok',
    'CC BY-SA 4.0',
  ),
  'kacang_panjang': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/7/78/Long_Bean.JPG/960px-Long_Bean.JPG',
    'Long Bean.JPG',
    'David',
    'Public domain',
  ),
  'kangkung': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0e/Water_spinach.jpg/960px-Water_spinach.jpg',
    'Water spinach.jpg',
    'Fumikas Sagisavas',
    'CC0',
  ),
  'kari_kacang_merah': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d1/Rajma.jpg/960px-Rajma.jpg',
    'Rajma.jpg',
    'rovingI',
    'CC BY 2.0',
  ),
  'kurma': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/26/2019_Dates_%2848608157288%29.jpg/960px-2019_Dates_%2848608157288%29.jpg',
    '2019 Dates (48608157288).jpg',
    'Michael Gaylard from Horsham, UK',
    'CC BY 2.0',
  ),
  'labu_siam': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/3e/Chayote_2.jpg/960px-Chayote_2.jpg',
    'Chayote 2.jpg',
    'Gaurav Dhwaj Khadka',
    'CC BY-SA 4.0',
  ),
  'meal_prep': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4a/Meal_prep_glass_container_%2845165270525%29.jpg/960px-Meal_prep_glass_container_%2845165270525%29.jpg',
    'Meal prep glass container (45165270525).jpg',
    'Ella Olsson from Stockholm, Sweden',
    'CC BY 2.0',
  ),
  'melon': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/9a/Cantaloupe.jpg/960px-Cantaloupe.jpg',
    'Cantaloupe.jpg',
    'Renee Comet (Photographer)',
    'Public domain',
  ),
  'nanas': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/ef/A_basket_of_pineapple_cut_fruit.JPG/960px-A_basket_of_pineapple_cut_fruit.JPG',
    'A basket of pineapple cut fruit.JPG',
    'Thamizhpparithi Maari',
    'CC BY-SA 3.0',
  ),
  'nasi_goreng': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/56/Nasi_Goreng_Telur_Balado.jpg/960px-Nasi_Goreng_Telur_Balado.jpg',
    'Nasi Goreng Telur Balado.jpg',
    'Indonesiagood',
    'CC BY 4.0',
  ),
  'nasi_merah': PhotoCredit(
    'https://upload.wikimedia.org/wikipedia/commons/8/8b/Patbap.jpg',
    'Patbap.jpg',
    '경빈마마',
    'CC BY 2.0 kr',
  ),
  'nila': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/81/Nila_bakar.jpg/960px-Nila_bakar.jpg',
    'Nila bakar.jpg',
    'Moh Taufiqurrohman',
    'CC BY-SA 4.0',
  ),
  'oatmeal': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1f/Banana_Oatmeal_Breakfast_Bowl_%2844302857265%29.jpg/960px-Banana_Oatmeal_Breakfast_Bowl_%2844302857265%29.jpg',
    'Banana Oatmeal Breakfast Bowl (44302857265).jpg',
    'Ella Olsson from Stockholm, Sweden',
    'CC BY 2.0',
  ),
  'omelet': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/47/Cha-om_omelette.jpg/960px-Cha-om_omelette.jpg',
    'Cha-om omelette.jpg',
    'Wagaung at English Wikipedia',
    'CC BY-SA 3.0',
  ),
  'pancake': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d7/Banana_on_pancake.jpg/960px-Banana_on_pancake.jpg',
    'Banana on pancake.jpg',
    'Brandon Martin-Anderson',
    'CC BY-SA 2.0',
  ),
  'pecel': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/33/Indonesian_Pecel_Menu.jpg/960px-Indonesian_Pecel_Menu.jpg',
    'Indonesian Pecel Menu.jpg',
    'Bajinra',
    'CC0',
  ),
  'pepaya': PhotoCredit(
    'https://upload.wikimedia.org/wikipedia/commons/6/6d/Papaya-Slices_53293-480x360_%284791934404%29.jpg',
    'Papaya-Slices 53293-480x360 (4791934404).jpg',
    'Emilian Robert Vicol from Com. Balanesti, Romania',
    'CC BY 2.0',
  ),
  'pepes_ikan': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2d/Pepes_ikan_emas_%28pais_lauk_mas%29_Sunda.jpg/960px-Pepes_ikan_emas_%28pais_lauk_mas%29_Sunda.jpg',
    'Pepes ikan emas (pais lauk mas) Sunda.jpg',
    'Gunawan Kartapranata',
    'CC BY-SA 3.0',
  ),
  'rawon': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/22/Restoran_Rawon_Rosobo_Mojoagung-3.jpg/960px-Restoran_Rawon_Rosobo_Mojoagung-3.jpg',
    'Restoran Rawon Rosobo Mojoagung-3.jpg',
    'Indonesiagood',
    'CC BY 4.0',
  ),
  'rice_bowl': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/46/Liat_Portal_for_Foodie_Disorder_-_Roasted_chicken_with_cauliflower_broccoli_potatoes_rice_and_salad.jpg/960px-Liat_Portal_for_Foodie_Disorder_-_Roasted_chicken_with_cauliflower_broccoli_potatoes_rice_and_salad.jpg',
    'Liat Portal for Foodie Disorder - Roasted chicken with cauliflower broccoli potatoes rice and salad.jpg',
    'HaJunkiyada',
    'CC BY-SA 4.0',
  ),
  'roti_telur': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/94/Smashed_Avocado_On_Toast_%28with_one_poached_egg%29_-_Jonny%27s_2026-01-06.jpg/960px-Smashed_Avocado_On_Toast_%28with_one_poached_egg%29_-_Jonny%27s_2026-01-06.jpg',
    'Smashed Avocado On Toast (with one poached egg) - Jonny\'s 2026-01-06.jpg',
    'Andy Li',
    'CC0',
  ),
  'salmon_panggang': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/95/Grilled_Teriyaki_Salmon_%2810900376705%29.jpg/960px-Grilled_Teriyaki_Salmon_%2810900376705%29.jpg',
    'Grilled Teriyaki Salmon (10900376705).jpg',
    'Prayitno / Thank you for (12 millions +) view from Los Angel',
    'CC BY 2.0',
  ),
  'sayur_asem': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/58/Sayur_asem_vegetable_soup.jpg/960px-Sayur_asem_vegetable_soup.jpg',
    'Sayur asem vegetable soup.jpg',
    'Sakurai Midori',
    'CC BY-SA 3.0',
  ),
  'sayur_bayam': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/fc/Sayur_bening_bayam_jagung.JPG/960px-Sayur_bening_bayam_jagung.JPG',
    'Sayur bening bayam jagung.JPG',
    'Midori',
    'CC BY 3.0',
  ),
  'semangka': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/ec/Slice_of_Watermelon_from_Wilson_Farm%2C_Lexington_MA.jpg/960px-Slice_of_Watermelon_from_Wilson_Farm%2C_Lexington_MA.jpg',
    'Slice of Watermelon from Wilson Farm, Lexington MA.jpg',
    'John Phelan',
    'CC BY-SA 3.0',
  ),
  'smoothie': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/6e/Banana_Smoothie.jpg/960px-Banana_Smoothie.jpg',
    'Banana Smoothie.jpg',
    'Ourlibrary',
    'CC0',
  ),
  'soto_ayam': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/69/Soto_Ayam_home-made.JPG/960px-Soto_Ayam_home-made.JPG',
    'Soto Ayam home-made.JPG',
    'Gunawan Kartapranata',
    'CC BY-SA 3.0',
  ),
  'sup_ayam': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/23/Liat_Portal_for_Foodie_Disorder_-_Chicken_dumpling_soup_with_root_vegetables_and_legumes.jpg/960px-Liat_Portal_for_Foodie_Disorder_-_Chicken_dumpling_soup_with_root_vegetables_and_legumes.jpg',
    'Liat Portal for Foodie Disorder - Chicken dumpling soup with root vegetables and legumes.jpg',
    'HaJunkiyada',
    'CC BY-SA 4.0',
  ),
  'tahu': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/1/1d/Tahu_digoreng.JPG/960px-Tahu_digoreng.JPG',
    'Tahu digoreng.JPG',
    'Sakurai Midori',
    'CC BY 3.0',
  ),
  'telur_rebus': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a4/Boiled_Egg_-_Crossection.jpg/960px-Boiled_Egg_-_Crossection.jpg',
    'Boiled Egg - Crossection.jpg',
    'Ramesh NG',
    'CC BY-SA 2.0',
  ),
  'tempe': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e1/Tempeh_%288681605421%29.jpg/960px-Tempeh_%288681605421%29.jpg',
    'Tempeh (8681605421).jpg',
    'Veganbaking.net from USA',
    'CC BY-SA 2.0',
  ),
  'tempe_bacem': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/88/42._Tahu_bacem_2.jpg/960px-42._Tahu_bacem_2.jpg',
    '42. Tahu bacem 2.jpg',
    'Danangtrihartanto',
    'CC BY-SA 4.0',
  ),
  'tumis_kangkung': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0f/Tumis_kangkung_Makassar.JPG/960px-Tumis_kangkung_Makassar.JPG',
    'Tumis kangkung Makassar.JPG',
    'Midori',
    'CC BY 3.0',
  ),
  'tuna_salad': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/e7/Tuna_Salad_with_sweet_corn.jpg/960px-Tuna_Salad_with_sweet_corn.jpg',
    'Tuna Salad with sweet corn.jpg',
    'Adesolive',
    'CC0',
  ),
  'ubi_rebus': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/9a/Boiled_sweet_Potatoes_and_carrot_with_vegetable_fish_sauce.jpg/960px-Boiled_sweet_Potatoes_and_carrot_with_vegetable_fish_sauce.jpg',
    'Boiled sweet Potatoes and carrot with vegetable fish sauce.jpg',
    'Halima Waziri',
    'CC BY-SA 4.0',
  ),
  'udang_tumis': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/9/91/DFC_2196_Close-up_of_a_stir-fry_featuring_shrimp_tossed_with_sliced_green_beans_and_carrots_in_a_savory_sauce.jpg/960px-DFC_2196_Close-up_of_a_stir-fry_featuring_shrimp_tossed_with_sliced_green_beans_and_carrots_in_a_savory_sauce.jpg',
    'DFC 2196 Close-up of a stir-fry featuring shrimp tossed with sliced green beans and carrots in a savory sauce.jpg',
    'PattayaPatrol',
    'CC BY-SA 4.0',
  ),
  'whey': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/68/User_measures_a_scoop_of_protein_powder_from_a_container_in_a_kitchen.jpg/960px-User_measures_a_scoop_of_protein_powder_from_a_container_in_a_kitchen.jpg',
    'User measures a scoop of protein powder from a container in a kitchen.jpg',
    'Shixart1985',
    'CC BY 2.0',
  ),
  'yogurt_bowl': PhotoCredit(
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/6c/Yogurt%2C_fruit%2C_granola_bowl_%2834999358091%29.jpg/960px-Yogurt%2C_fruit%2C_granola_bowl_%2834999358091%29.jpg',
    'Yogurt, fruit, granola bowl (34999358091).jpg',
    'T.Tseng',
    'CC BY 2.0',
  ),
};
