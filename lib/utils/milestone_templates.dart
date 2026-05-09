class MilestoneTemplate {
  final String title;
  final String description;
  final String emoji;
  final String category;

  const MilestoneTemplate({
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
  });
}

const List<MilestoneTemplate> babyMilestones = [
  // ── Birth & Hospital ──────────────────────────────────────────────────────
  MilestoneTemplate(
    emoji: '🏠',
    category: 'Birth & Hospital',
    title: 'Came Home from Hospital',
    description: 'The first day our little one came home. A whole new chapter begins!',
  ),
  MilestoneTemplate(
    emoji: '🛁',
    category: 'Birth & Hospital',
    title: 'First Bath',
    description: 'Splish splash! Our very first bath time adventure.',
  ),
  MilestoneTemplate(
    emoji: '💉',
    category: 'Birth & Hospital',
    title: 'First Vaccination',
    description: 'So brave for the very first vaccination.',
  ),
  MilestoneTemplate(
    emoji: '🩺',
    category: 'Birth & Hospital',
    title: 'First Doctor Visit',
    description: 'First check-up with the paediatrician. All healthy!',
  ),

  // ── First Weeks ────────────────────────────────────────────────────────────
  MilestoneTemplate(
    emoji: '😊',
    category: 'First Weeks',
    title: 'First Smile',
    description: 'That heart-melting first real smile — the whole world lit up.',
  ),
  MilestoneTemplate(
    emoji: '🤣',
    category: 'First Weeks',
    title: 'First Laugh',
    description: 'The best sound in the world — our baby laughed for the first time!',
  ),
  MilestoneTemplate(
    emoji: '😴',
    category: 'First Weeks',
    title: 'Slept Through the Night',
    description: 'A milestone for everyone — finally a full night of sleep!',
  ),
  MilestoneTemplate(
    emoji: '🫗',
    category: 'First Weeks',
    title: 'First Bottle Feed',
    description: 'Took to the bottle like a champ today.',
  ),

  // ── Development ────────────────────────────────────────────────────────────
  MilestoneTemplate(
    emoji: '💪',
    category: 'Development',
    title: 'Holds Head Up',
    description: 'Strong little neck! Held their head up all on their own.',
  ),
  MilestoneTemplate(
    emoji: '🔄',
    category: 'Development',
    title: 'Rolls Over',
    description: 'Rolled over all by themselves for the very first time!',
  ),
  MilestoneTemplate(
    emoji: '🪑',
    category: 'Development',
    title: 'Sits Without Support',
    description: 'Sitting up independently — no wobbles!',
  ),
  MilestoneTemplate(
    emoji: '🦷',
    category: 'Development',
    title: 'First Tooth',
    description: 'That tiny first tooth popped through! Everything is now chewable.',
  ),
  MilestoneTemplate(
    emoji: '✊',
    category: 'Development',
    title: 'Pincer Grasp',
    description: 'Picking up tiny things with little fingers — such precision!',
  ),
  MilestoneTemplate(
    emoji: '👀',
    category: 'Development',
    title: 'Tracks Objects with Eyes',
    description: 'Eyes following objects and faces — fully alert and curious.',
  ),

  // ── Feeding ────────────────────────────────────────────────────────────────
  MilestoneTemplate(
    emoji: '🥄',
    category: 'Feeding',
    title: 'First Solid Food',
    description: 'The first spoonful of solid food — a big moment for the whole family!',
  ),
  MilestoneTemplate(
    emoji: '🥦',
    category: 'Feeding',
    title: 'Tried a New Food',
    description: 'Adventurous eating! Tried a brand new food today.',
  ),
  MilestoneTemplate(
    emoji: '🍰',
    category: 'Feeding',
    title: 'First Birthday Cake',
    description: 'The very first taste of cake — frosting everywhere!',
  ),

  // ── Movement ───────────────────────────────────────────────────────────────
  MilestoneTemplate(
    emoji: '🐛',
    category: 'Movement',
    title: 'Started Crawling',
    description: 'Off to the races! Crawling for the first time.',
  ),
  MilestoneTemplate(
    emoji: '🧱',
    category: 'Movement',
    title: 'Pulls to Stand',
    description: 'Grabbed the furniture and stood right up. So proud!',
  ),
  MilestoneTemplate(
    emoji: '👣',
    category: 'Movement',
    title: 'First Steps',
    description: 'Those very first wobbly steps — one giant leap for our little one!',
  ),
  MilestoneTemplate(
    emoji: '🏃',
    category: 'Movement',
    title: 'Walks Independently',
    description: 'Walking confidently on their own. No stopping them now!',
  ),
  MilestoneTemplate(
    emoji: '⚡',
    category: 'Movement',
    title: 'First Run',
    description: 'Full-on running! Keeping up is now a challenge.',
  ),
  MilestoneTemplate(
    emoji: '🪜',
    category: 'Movement',
    title: 'Climbed Stairs',
    description: 'Climbed up the stairs all on their own for the first time.',
  ),

  // ── Communication ──────────────────────────────────────────────────────────
  MilestoneTemplate(
    emoji: '👶',
    category: 'Communication',
    title: 'Said "Mama" or "Dada"',
    description: 'The most beautiful words we\'ve ever heard.',
  ),
  MilestoneTemplate(
    emoji: '💬',
    category: 'Communication',
    title: 'First Word',
    description: 'A real, intentional first word!',
  ),
  MilestoneTemplate(
    emoji: '🗣️',
    category: 'Communication',
    title: 'First Sentence',
    description: 'Stringing words together into a proper sentence for the first time.',
  ),
  MilestoneTemplate(
    emoji: '👋',
    category: 'Communication',
    title: 'Waves Bye-Bye',
    description: 'The cutest little wave goodbye!',
  ),
  MilestoneTemplate(
    emoji: '👏',
    category: 'Communication',
    title: 'Claps Hands',
    description: 'Clapping along with such joy!',
  ),
  MilestoneTemplate(
    emoji: '🫶',
    category: 'Communication',
    title: 'First "I Love You"',
    description: 'Said "I love you" for the very first time. Heart officially melted.',
  ),

  // ── Big Moments ────────────────────────────────────────────────────────────
  MilestoneTemplate(
    emoji: '✂️',
    category: 'Big Moments',
    title: 'First Haircut',
    description: 'Those first precious locks of hair — we\'re keeping a snippet forever.',
  ),
  MilestoneTemplate(
    emoji: '🎂',
    category: 'Big Moments',
    title: 'First Birthday',
    description: 'One whole year of absolute joy. Happy birthday!',
  ),
  MilestoneTemplate(
    emoji: '🎄',
    category: 'Big Moments',
    title: 'First Christmas',
    description: 'Their very first Christmas — the magic through their eyes is everything.',
  ),
  MilestoneTemplate(
    emoji: '🎆',
    category: 'Big Moments',
    title: 'First New Year',
    description: 'Ringing in the new year with our little one for the first time.',
  ),
  MilestoneTemplate(
    emoji: '✈️',
    category: 'Big Moments',
    title: 'First Flight / Trip',
    description: 'Our little traveller took their first flight today.',
  ),
  MilestoneTemplate(
    emoji: '🏫',
    category: 'Big Moments',
    title: 'First Day at Daycare',
    description: 'A big day for everyone — the first drop-off at daycare.',
  ),
  MilestoneTemplate(
    emoji: '🎒',
    category: 'Big Moments',
    title: 'First Day at School',
    description: 'Backpack on, off to school! Growing up so fast.',
  ),
  MilestoneTemplate(
    emoji: '🚽',
    category: 'Big Moments',
    title: 'Potty Training Complete',
    description: 'Fully potty trained — nappies are officially a thing of the past!',
  ),
  MilestoneTemplate(
    emoji: '🤝',
    category: 'Big Moments',
    title: 'First Playdate',
    description: 'The first real playdate with a friend — little friendships beginning.',
  ),
  MilestoneTemplate(
    emoji: '🏊',
    category: 'Big Moments',
    title: 'First Swim',
    description: 'Splashing in the water for the very first time!',
  ),
];

List<String> get milestoneCategories =>
    babyMilestones.map((m) => m.category).toSet().toList();
