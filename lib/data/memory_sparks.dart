// Built-in Memory Sparks — age-appropriate activity ideas that can inspire
// a new memory. Sparks are shown based on the child's current age in months.

enum SparkCategory {
  creative,
  outdoor,
  learning,
  music,
  cooking,
  play,
  sensory,
  bonding,
}

extension SparkCategoryLabel on SparkCategory {
  String get label => switch (this) {
        SparkCategory.creative => 'Creative',
        SparkCategory.outdoor => 'Outdoor',
        SparkCategory.learning => 'Learning',
        SparkCategory.music => 'Music',
        SparkCategory.cooking => 'Cooking',
        SparkCategory.play => 'Play',
        SparkCategory.sensory => 'Sensory',
        SparkCategory.bonding => 'Bonding',
      };

  String get emoji => switch (this) {
        SparkCategory.creative => '🎨',
        SparkCategory.outdoor => '🌿',
        SparkCategory.learning => '📚',
        SparkCategory.music => '🎵',
        SparkCategory.cooking => '🍪',
        SparkCategory.play => '🎮',
        SparkCategory.sensory => '🧘',
        SparkCategory.bonding => '🤝',
      };
}

class MemorySpark {
  final String id;
  final String title;
  final String description;
  final SparkCategory category;
  final int ageMonthsMin;
  final int ageMonthsMax; // 999 = no upper limit

  const MemorySpark({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.ageMonthsMin,
    this.ageMonthsMax = 999,
  });
}

// ── Built-in sparks ───────────────────────────────────────────────────────────

const builtInSparks = <MemorySpark>[

  // ── 0–3 months ──────────────────────────────────────────────────────────────
  MemorySpark(id: 'sp_0_1', ageMonthsMin: 0, ageMonthsMax: 3,
    category: SparkCategory.sensory,
    title: 'Tummy time rainbow',
    description: 'Place colourful toys just out of reach during tummy time. Watch them push up and reach!'),
  MemorySpark(id: 'sp_0_2', ageMonthsMin: 0, ageMonthsMax: 3,
    category: SparkCategory.bonding,
    title: 'Sing just to them',
    description: 'Pick a silly song and sing it every day this week. Watch for the first real smile.'),
  MemorySpark(id: 'sp_0_3', ageMonthsMin: 0, ageMonthsMax: 3,
    category: SparkCategory.sensory,
    title: 'Mirror magic',
    description: 'Hold them up to a mirror and watch their puzzled face discovering their reflection.'),
  MemorySpark(id: 'sp_0_4', ageMonthsMin: 0, ageMonthsMax: 3,
    category: SparkCategory.bonding,
    title: 'Gentle baby massage',
    description: 'After bath, use warm lotion for a 5-minute gentle massage. Great for bonding and sleep.'),

  // ── 4–6 months ──────────────────────────────────────────────────────────────
  MemorySpark(id: 'sp_4_1', ageMonthsMin: 4, ageMonthsMax: 6,
    category: SparkCategory.sensory,
    title: 'Splash splash water play',
    description: 'A shallow basin of warm water + cups = endless fascination. Watch those eyes go wide.'),
  MemorySpark(id: 'sp_4_2', ageMonthsMin: 4, ageMonthsMax: 6,
    category: SparkCategory.music,
    title: 'Rattle band',
    description: 'Shake rattles, crinkle toys, and bang soft drums together. Their first band performance!'),
  MemorySpark(id: 'sp_4_3', ageMonthsMin: 4, ageMonthsMax: 6,
    category: SparkCategory.music,
    title: 'Dance party for two',
    description: 'Hold them close and sway to three very different songs — classical, pop, and a silly one.'),
  MemorySpark(id: 'sp_4_4', ageMonthsMin: 4, ageMonthsMax: 6,
    category: SparkCategory.sensory,
    title: 'Texture adventure',
    description: 'Let them touch safe different textures: velvet, satin, a cold spoon, a soft brush.'),

  // ── 7–11 months ─────────────────────────────────────────────────────────────
  MemorySpark(id: 'sp_7_1', ageMonthsMin: 7, ageMonthsMax: 11,
    category: SparkCategory.play,
    title: 'Peek-a-boo champion',
    description: 'Try 5 different variations of peek-a-boo. Behind hands, a blanket, around a door…'),
  MemorySpark(id: 'sp_7_2', ageMonthsMin: 7, ageMonthsMax: 11,
    category: SparkCategory.learning,
    title: 'First board books',
    description: 'Read the same simple board book 3 times. Point at pictures and name everything.'),
  MemorySpark(id: 'sp_7_3', ageMonthsMin: 7, ageMonthsMax: 11,
    category: SparkCategory.play,
    title: 'Ball rolling back and forth',
    description: 'Sit face to face on the floor and roll a soft ball back and forth. First "sport" together!'),
  MemorySpark(id: 'sp_7_4', ageMonthsMin: 7, ageMonthsMax: 11,
    category: SparkCategory.cooking,
    title: 'First finger foods',
    description: 'Prepare soft pea-sized pieces of banana, avocado, or cooked carrot. Watch the discovery.'),

  // ── 12–17 months ────────────────────────────────────────────────────────────
  MemorySpark(id: 'sp_12_1', ageMonthsMin: 12, ageMonthsMax: 17,
    category: SparkCategory.creative,
    title: 'Finger painting',
    description: 'Baby-safe paints on a big sheet. No brushes, just hands. Expect a masterpiece and a mess.'),
  MemorySpark(id: 'sp_12_2', ageMonthsMin: 12, ageMonthsMax: 17,
    category: SparkCategory.play,
    title: 'Block tower challenge',
    description: 'Stack towers together, then let them knock each one down. How high can you go?'),
  MemorySpark(id: 'sp_12_3', ageMonthsMin: 12, ageMonthsMax: 17,
    category: SparkCategory.outdoor,
    title: 'First nature walk',
    description: 'Slow walk collecting one leaf, one stick, one stone. Name everything you find.'),
  MemorySpark(id: 'sp_12_4', ageMonthsMin: 12, ageMonthsMax: 17,
    category: SparkCategory.cooking,
    title: 'Kitchen helper',
    description: 'Let them stir, pour, and pat dough while you cook. A safe spoon is their favourite tool.'),

  // ── 18–23 months ────────────────────────────────────────────────────────────
  MemorySpark(id: 'sp_18_1', ageMonthsMin: 18, ageMonthsMax: 23,
    category: SparkCategory.creative,
    title: 'Playdough session',
    description: 'Roll snakes, make balls, squish flat. No goal — just create together for 20 minutes.'),
  MemorySpark(id: 'sp_18_2', ageMonthsMin: 18, ageMonthsMax: 23,
    category: SparkCategory.outdoor,
    title: 'Bubble chasing',
    description: 'Blow bubbles outside and run to pop them. Add counting for extra fun.'),
  MemorySpark(id: 'sp_18_3', ageMonthsMin: 18, ageMonthsMax: 23,
    category: SparkCategory.play,
    title: 'Living room pretend picnic',
    description: 'Lay out a blanket, pack snacks in a bag, and "have a picnic" in the middle of the room.'),
  MemorySpark(id: 'sp_18_4', ageMonthsMin: 18, ageMonthsMax: 23,
    category: SparkCategory.learning,
    title: 'Simple puzzle together',
    description: 'A 3–4 piece puzzle. Let them figure it out, only help when truly stuck.'),

  // ── 2–3 years ───────────────────────────────────────────────────────────────
  MemorySpark(id: 'sp_24_1', ageMonthsMin: 24, ageMonthsMax: 47,
    category: SparkCategory.cooking,
    title: 'Bake cookies together',
    description: 'Simple sugar or chocolate chip cookies. Let them pour, mix, and cut shapes.'),
  MemorySpark(id: 'sp_24_2', ageMonthsMin: 24, ageMonthsMax: 47,
    category: SparkCategory.play,
    title: 'Living room obstacle course',
    description: 'Pillows, cushions, and blankets become mountains, tunnels, and rivers. Go!'),
  MemorySpark(id: 'sp_24_3', ageMonthsMin: 24, ageMonthsMax: 47,
    category: SparkCategory.outdoor,
    title: 'Nature scavenger hunt',
    description: 'List: something red, something round, something rough, something tiny. Who finds them first?'),
  MemorySpark(id: 'sp_24_4', ageMonthsMin: 24, ageMonthsMax: 47,
    category: SparkCategory.creative,
    title: 'Water painting outside',
    description: 'A bucket of water and a big paintbrush — paint the fence, pavement, or garden wall.'),
  MemorySpark(id: 'sp_24_5', ageMonthsMin: 24, ageMonthsMax: 47,
    category: SparkCategory.music,
    title: 'Kitchen drum kit',
    description: 'Pots, wooden spoons, and plastic containers become a drum kit. Let the concert begin.'),

  // ── 3–5 years ───────────────────────────────────────────────────────────────
  MemorySpark(id: 'sp_36_1', ageMonthsMin: 36, ageMonthsMax: 71,
    category: SparkCategory.learning,
    title: 'Make up a story together',
    description: 'Take turns adding one sentence to a story. See where it goes — the sillier the better.'),
  MemorySpark(id: 'sp_36_2', ageMonthsMin: 36, ageMonthsMax: 71,
    category: SparkCategory.outdoor,
    title: 'Plant a seed',
    description: 'Plant a sunflower or bean seed together. Water it daily and measure growth each week.'),
  MemorySpark(id: 'sp_36_3', ageMonthsMin: 36, ageMonthsMax: 71,
    category: SparkCategory.creative,
    title: 'Make playdough from scratch',
    description: 'Flour, salt, oil, cream of tartar, water — cook together and create all afternoon.'),
  MemorySpark(id: 'sp_36_4', ageMonthsMin: 36, ageMonthsMax: 71,
    category: SparkCategory.outdoor,
    title: 'Star gazing night',
    description: 'Lay on a blanket outside after dark. Find one constellation and make up a story about it.'),
  MemorySpark(id: 'sp_36_5', ageMonthsMin: 36, ageMonthsMax: 71,
    category: SparkCategory.cooking,
    title: 'Homemade pizza night',
    description: 'Let them top their own mini pizza with whatever they want. No veto rights on toppings!'),

  // ── 5–7 years ───────────────────────────────────────────────────────────────
  MemorySpark(id: 'sp_60_1', ageMonthsMin: 60, ageMonthsMax: 95,
    category: SparkCategory.cooking,
    title: 'Cook a real meal together',
    description: 'Scrambled eggs, pasta, or simple sandwiches — they do as much as safely possible.'),
  MemorySpark(id: 'sp_60_2', ageMonthsMin: 60, ageMonthsMax: 95,
    category: SparkCategory.creative,
    title: 'Build the ultimate fort',
    description: 'Every blanket, pillow, and chair in the house. Build a fort big enough to live in for a day.'),
  MemorySpark(id: 'sp_60_3', ageMonthsMin: 60, ageMonthsMax: 95,
    category: SparkCategory.learning,
    title: 'Library adventure',
    description: 'Go to the library and each pick 3 books entirely by the cover. Read one together tonight.'),
  MemorySpark(id: 'sp_60_4', ageMonthsMin: 60, ageMonthsMax: 95,
    category: SparkCategory.bonding,
    title: 'Letter to future self',
    description: 'Write a letter together about their life right now. Seal it in an envelope to open in 5 years.'),
  MemorySpark(id: 'sp_60_5', ageMonthsMin: 60, ageMonthsMax: 95,
    category: SparkCategory.outdoor,
    title: 'Photo walk',
    description: 'Hand them a camera or phone and go on a walk where they photograph everything interesting.'),

  // ── 7+ years ────────────────────────────────────────────────────────────────
  MemorySpark(id: 'sp_84_1', ageMonthsMin: 84,
    category: SparkCategory.learning,
    title: 'Learn something new together',
    description: 'Pick one skill neither of you knows — origami, juggling, a magic trick. Learn it together.'),
  MemorySpark(id: 'sp_84_2', ageMonthsMin: 84,
    category: SparkCategory.bonding,
    title: 'Board game tournament',
    description: 'Play three different games in one evening. Keep a score chart. Loser picks dinner.'),
  MemorySpark(id: 'sp_84_3', ageMonthsMin: 84,
    category: SparkCategory.outdoor,
    title: 'Bike adventure',
    description: 'Pick a direction and ride for 20 minutes. Stop at whatever looks interesting.'),
  MemorySpark(id: 'sp_84_4', ageMonthsMin: 84,
    category: SparkCategory.creative,
    title: 'Make a mini documentary',
    description: 'Film a short "documentary" about a day in their life. Watch it together with popcorn.'),
  MemorySpark(id: 'sp_84_5', ageMonthsMin: 84,
    category: SparkCategory.bonding,
    title: 'Cook from a new country',
    description: 'Pick a country on a map, find a simple recipe from there, and cook it together.'),
];

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Sparks appropriate for [ageMonths], optionally filtered by [category].
List<MemorySpark> sparksForAge(int ageMonths, {SparkCategory? category}) {
  var list = builtInSparks.where((s) =>
      ageMonths >= s.ageMonthsMin && ageMonths <= s.ageMonthsMax);
  if (category != null) list = list.where((s) => s.category == category);
  return list.toList();
}

/// A stable "spark of the day" for a given child: changes daily, repeatable
/// within the same day, biased toward age-appropriate sparks.
MemorySpark sparkOfTheDay(int ageMonths) {
  final ageSparks = sparksForAge(ageMonths);
  final pool = ageSparks.isNotEmpty ? ageSparks : builtInSparks;
  final dayIndex = DateTime.now().difference(DateTime(2024)).inDays;
  return pool[dayIndex % pool.length];
}
