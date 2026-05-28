// CDC "Learn the Signs. Act Early." developmental milestones (2022 revision).
// Organised by age group then domain.

enum DevDomain { social, language, cognitive, motor }

extension DevDomainLabel on DevDomain {
  String get label => switch (this) {
        DevDomain.social => 'Social & Emotional',
        DevDomain.language => 'Language & Communication',
        DevDomain.cognitive => 'Cognitive',
        DevDomain.motor => 'Movement & Physical',
      };

  String get emoji => switch (this) {
        DevDomain.social => '💛',
        DevDomain.language => '💬',
        DevDomain.cognitive => '🧠',
        DevDomain.motor => '🏃',
      };
}

class DevMilestone {
  final String id;
  final int ageMonths;
  final DevDomain domain;
  final String title;

  const DevMilestone({
    required this.id,
    required this.ageMonths,
    required this.domain,
    required this.title,
  });
}

// ── Age group labels ───────────────────────────────────────────────────────────

const cdcAgeGroups = <int>[2, 4, 6, 9, 12, 15, 18, 24, 36, 48, 60];

String cdcAgeLabel(int months) => switch (months) {
      2 => '2 Months',
      4 => '4 Months',
      6 => '6 Months',
      9 => '9 Months',
      12 => '12 Months',
      15 => '15 Months',
      18 => '18 Months',
      24 => '2 Years',
      36 => '3 Years',
      48 => '4 Years',
      60 => '5 Years',
      _ => '${months}m',
    };

// ── Milestone table ───────────────────────────────────────────────────────────

const cdcMilestones = <DevMilestone>[
  // ── 2 months ────────────────────────────────────────────────────────────────
  DevMilestone(id: 'ms_2_s1', ageMonths: 2, domain: DevDomain.social,
      title: 'Calms down when spoken to or picked up'),
  DevMilestone(id: 'ms_2_s2', ageMonths: 2, domain: DevDomain.social,
      title: 'Looks at your face'),
  DevMilestone(id: 'ms_2_s3', ageMonths: 2, domain: DevDomain.social,
      title: 'Smiles when you talk or smile at them'),
  DevMilestone(id: 'ms_2_l1', ageMonths: 2, domain: DevDomain.language,
      title: 'Makes sounds other than crying'),
  DevMilestone(id: 'ms_2_l2', ageMonths: 2, domain: DevDomain.language,
      title: 'Reacts to loud sounds'),
  DevMilestone(id: 'ms_2_c1', ageMonths: 2, domain: DevDomain.cognitive,
      title: 'Watches you as you move'),
  DevMilestone(id: 'ms_2_c2', ageMonths: 2, domain: DevDomain.cognitive,
      title: 'Looks at a toy for several seconds'),
  DevMilestone(id: 'ms_2_m1', ageMonths: 2, domain: DevDomain.motor,
      title: 'Holds head up when on tummy'),
  DevMilestone(id: 'ms_2_m2', ageMonths: 2, domain: DevDomain.motor,
      title: 'Moves both arms and legs'),
  DevMilestone(id: 'ms_2_m3', ageMonths: 2, domain: DevDomain.motor,
      title: 'Opens hands briefly'),

  // ── 4 months ────────────────────────────────────────────────────────────────
  DevMilestone(id: 'ms_4_s1', ageMonths: 4, domain: DevDomain.social,
      title: 'Smiles on their own to get your attention'),
  DevMilestone(id: 'ms_4_s2', ageMonths: 4, domain: DevDomain.social,
      title: 'Chuckles when you try to make them laugh'),
  DevMilestone(id: 'ms_4_s3', ageMonths: 4, domain: DevDomain.social,
      title: 'Makes sounds or moves to get your attention'),
  DevMilestone(id: 'ms_4_l1', ageMonths: 4, domain: DevDomain.language,
      title: 'Makes sounds like "ooooo" and "aahh" (cooing)'),
  DevMilestone(id: 'ms_4_l2', ageMonths: 4, domain: DevDomain.language,
      title: 'Makes sounds back when you talk to them'),
  DevMilestone(id: 'ms_4_l3', ageMonths: 4, domain: DevDomain.language,
      title: 'Turns head toward the sound of your voice'),
  DevMilestone(id: 'ms_4_c1', ageMonths: 4, domain: DevDomain.cognitive,
      title: 'Shows hunger by crying or fussing'),
  DevMilestone(id: 'ms_4_c2', ageMonths: 4, domain: DevDomain.cognitive,
      title: 'Looks at hands with interest'),
  DevMilestone(id: 'ms_4_m1', ageMonths: 4, domain: DevDomain.motor,
      title: 'Holds head steady without support when held'),
  DevMilestone(id: 'ms_4_m2', ageMonths: 4, domain: DevDomain.motor,
      title: 'Holds a toy when you put it in their hand'),
  DevMilestone(id: 'ms_4_m3', ageMonths: 4, domain: DevDomain.motor,
      title: 'Pushes up onto elbows when on tummy'),
  DevMilestone(id: 'ms_4_m4', ageMonths: 4, domain: DevDomain.motor,
      title: 'Brings hands to mouth'),

  // ── 6 months ────────────────────────────────────────────────────────────────
  DevMilestone(id: 'ms_6_s1', ageMonths: 6, domain: DevDomain.social,
      title: 'Knows familiar people'),
  DevMilestone(id: 'ms_6_s2', ageMonths: 6, domain: DevDomain.social,
      title: 'Likes to look at themselves in a mirror'),
  DevMilestone(id: 'ms_6_s3', ageMonths: 6, domain: DevDomain.social,
      title: 'Laughs'),
  DevMilestone(id: 'ms_6_l1', ageMonths: 6, domain: DevDomain.language,
      title: 'Takes turns making sounds with you'),
  DevMilestone(id: 'ms_6_l2', ageMonths: 6, domain: DevDomain.language,
      title: 'Blows "raspberries" (sticks tongue out and blows)'),
  DevMilestone(id: 'ms_6_l3', ageMonths: 6, domain: DevDomain.language,
      title: 'Makes squealing noises'),
  DevMilestone(id: 'ms_6_c1', ageMonths: 6, domain: DevDomain.cognitive,
      title: 'Puts things in their mouth to explore them'),
  DevMilestone(id: 'ms_6_c2', ageMonths: 6, domain: DevDomain.cognitive,
      title: 'Reaches to grab a toy'),
  DevMilestone(id: 'ms_6_c3', ageMonths: 6, domain: DevDomain.cognitive,
      title: 'Closes lips to show they don\'t want more food'),
  DevMilestone(id: 'ms_6_m1', ageMonths: 6, domain: DevDomain.motor,
      title: 'Rolls from tummy to back'),
  DevMilestone(id: 'ms_6_m2', ageMonths: 6, domain: DevDomain.motor,
      title: 'Pushes up with straight arms when on tummy'),
  DevMilestone(id: 'ms_6_m3', ageMonths: 6, domain: DevDomain.motor,
      title: 'Leans on hands to support themselves when sitting'),

  // ── 9 months ────────────────────────────────────────────────────────────────
  DevMilestone(id: 'ms_9_s1', ageMonths: 9, domain: DevDomain.social,
      title: 'Is shy or clingy around strangers'),
  DevMilestone(id: 'ms_9_s2', ageMonths: 9, domain: DevDomain.social,
      title: 'Shows several facial expressions'),
  DevMilestone(id: 'ms_9_s3', ageMonths: 9, domain: DevDomain.social,
      title: 'Looks when you call their name'),
  DevMilestone(id: 'ms_9_s4', ageMonths: 9, domain: DevDomain.social,
      title: 'Smiles or laughs when you play peek-a-boo'),
  DevMilestone(id: 'ms_9_l1', ageMonths: 9, domain: DevDomain.language,
      title: 'Makes many different sounds like "mamamama" and "bababababa"'),
  DevMilestone(id: 'ms_9_l2', ageMonths: 9, domain: DevDomain.language,
      title: 'Lifts arms up to be picked up'),
  DevMilestone(id: 'ms_9_c1', ageMonths: 9, domain: DevDomain.cognitive,
      title: 'Looks for objects when dropped out of sight'),
  DevMilestone(id: 'ms_9_c2', ageMonths: 9, domain: DevDomain.cognitive,
      title: 'Bangs two things together'),
  DevMilestone(id: 'ms_9_m1', ageMonths: 9, domain: DevDomain.motor,
      title: 'Gets to a sitting position by themselves'),
  DevMilestone(id: 'ms_9_m2', ageMonths: 9, domain: DevDomain.motor,
      title: 'Moves things from one hand to the other'),
  DevMilestone(id: 'ms_9_m3', ageMonths: 9, domain: DevDomain.motor,
      title: 'Sits without support'),

  // ── 12 months ───────────────────────────────────────────────────────────────
  DevMilestone(id: 'ms_12_s1', ageMonths: 12, domain: DevDomain.social,
      title: 'Plays games with you like pat-a-cake'),
  DevMilestone(id: 'ms_12_l1', ageMonths: 12, domain: DevDomain.language,
      title: 'Waves "bye-bye"'),
  DevMilestone(id: 'ms_12_l2', ageMonths: 12, domain: DevDomain.language,
      title: 'Calls a parent "mama" or "dada" or another special name'),
  DevMilestone(id: 'ms_12_l3', ageMonths: 12, domain: DevDomain.language,
      title: 'Understands "no"'),
  DevMilestone(id: 'ms_12_c1', ageMonths: 12, domain: DevDomain.cognitive,
      title: 'Puts something in a container'),
  DevMilestone(id: 'ms_12_c2', ageMonths: 12, domain: DevDomain.cognitive,
      title: 'Looks for things they see you hide'),
  DevMilestone(id: 'ms_12_m1', ageMonths: 12, domain: DevDomain.motor,
      title: 'Pulls up to stand'),
  DevMilestone(id: 'ms_12_m2', ageMonths: 12, domain: DevDomain.motor,
      title: 'Walks holding on to furniture'),
  DevMilestone(id: 'ms_12_m3', ageMonths: 12, domain: DevDomain.motor,
      title: 'Drinks from a cup without a lid with help'),
  DevMilestone(id: 'ms_12_m4', ageMonths: 12, domain: DevDomain.motor,
      title: 'Picks up things between thumb and pointer finger'),

  // ── 15 months ───────────────────────────────────────────────────────────────
  DevMilestone(id: 'ms_15_s1', ageMonths: 15, domain: DevDomain.social,
      title: 'Copies other children while playing'),
  DevMilestone(id: 'ms_15_s2', ageMonths: 15, domain: DevDomain.social,
      title: 'Shows you things they like'),
  DevMilestone(id: 'ms_15_s3', ageMonths: 15, domain: DevDomain.social,
      title: 'Claps when excited'),
  DevMilestone(id: 'ms_15_s4', ageMonths: 15, domain: DevDomain.social,
      title: 'Shows you affection (hugs, cuddles, or kisses)'),
  DevMilestone(id: 'ms_15_l1', ageMonths: 15, domain: DevDomain.language,
      title: 'Says 3 or more words besides "mama" or "dada"'),
  DevMilestone(id: 'ms_15_l2', ageMonths: 15, domain: DevDomain.language,
      title: 'Follows 1-step directions'),
  DevMilestone(id: 'ms_15_c1', ageMonths: 15, domain: DevDomain.cognitive,
      title: 'Tries to use things the right way (phone, cup, book)'),
  DevMilestone(id: 'ms_15_c2', ageMonths: 15, domain: DevDomain.cognitive,
      title: 'Stacks at least two small objects'),
  DevMilestone(id: 'ms_15_m1', ageMonths: 15, domain: DevDomain.motor,
      title: 'Takes a few steps on their own'),
  DevMilestone(id: 'ms_15_m2', ageMonths: 15, domain: DevDomain.motor,
      title: 'Uses fingers to feed themselves food'),

  // ── 18 months ───────────────────────────────────────────────────────────────
  DevMilestone(id: 'ms_18_s1', ageMonths: 18, domain: DevDomain.social,
      title: 'Moves away from you but looks to make sure you\'re close'),
  DevMilestone(id: 'ms_18_s2', ageMonths: 18, domain: DevDomain.social,
      title: 'Points to show you something interesting'),
  DevMilestone(id: 'ms_18_s3', ageMonths: 18, domain: DevDomain.social,
      title: 'Helps you dress them'),
  DevMilestone(id: 'ms_18_l1', ageMonths: 18, domain: DevDomain.language,
      title: 'Tries to say 3 or more words besides "mama" or "dada"'),
  DevMilestone(id: 'ms_18_l2', ageMonths: 18, domain: DevDomain.language,
      title: 'Follows 1-step directions without gestures'),
  DevMilestone(id: 'ms_18_c1', ageMonths: 18, domain: DevDomain.cognitive,
      title: 'Copies you doing chores (sweeping, wiping)'),
  DevMilestone(id: 'ms_18_c2', ageMonths: 18, domain: DevDomain.cognitive,
      title: 'Plays with toys in a simple way (pushing a toy car)'),
  DevMilestone(id: 'ms_18_m1', ageMonths: 18, domain: DevDomain.motor,
      title: 'Walks without holding on to anyone or anything'),
  DevMilestone(id: 'ms_18_m2', ageMonths: 18, domain: DevDomain.motor,
      title: 'Scribbles'),
  DevMilestone(id: 'ms_18_m3', ageMonths: 18, domain: DevDomain.motor,
      title: 'Drinks from a cup without a lid, may spill some'),

  // ── 24 months (2 years) ─────────────────────────────────────────────────────
  DevMilestone(id: 'ms_24_s1', ageMonths: 24, domain: DevDomain.social,
      title: 'Notices when others are hurt or upset'),
  DevMilestone(id: 'ms_24_s2', ageMonths: 24, domain: DevDomain.social,
      title: 'Looks at your face to see how to react in a new situation'),
  DevMilestone(id: 'ms_24_l1', ageMonths: 24, domain: DevDomain.language,
      title: 'Points to things in a book when you ask'),
  DevMilestone(id: 'ms_24_l2', ageMonths: 24, domain: DevDomain.language,
      title: 'Says at least 2 words together ("more milk")'),
  DevMilestone(id: 'ms_24_l3', ageMonths: 24, domain: DevDomain.language,
      title: 'Points to at least 2 body parts when asked'),
  DevMilestone(id: 'ms_24_c1', ageMonths: 24, domain: DevDomain.cognitive,
      title: 'Holds something in one hand while using the other'),
  DevMilestone(id: 'ms_24_c2', ageMonths: 24, domain: DevDomain.cognitive,
      title: 'Tries to use switches, knobs, or buttons on a toy'),
  DevMilestone(id: 'ms_24_c3', ageMonths: 24, domain: DevDomain.cognitive,
      title: 'Plays with more than one toy at the same time'),
  DevMilestone(id: 'ms_24_m1', ageMonths: 24, domain: DevDomain.motor,
      title: 'Runs'),
  DevMilestone(id: 'ms_24_m2', ageMonths: 24, domain: DevDomain.motor,
      title: 'Walks up a few stairs with or without help'),
  DevMilestone(id: 'ms_24_m3', ageMonths: 24, domain: DevDomain.motor,
      title: 'Eats with a spoon'),

  // ── 36 months (3 years) ─────────────────────────────────────────────────────
  DevMilestone(id: 'ms_36_s1', ageMonths: 36, domain: DevDomain.social,
      title: 'Calms down within 10 minutes after you leave (e.g. at daycare)'),
  DevMilestone(id: 'ms_36_s2', ageMonths: 36, domain: DevDomain.social,
      title: 'Notices other children and joins them to play'),
  DevMilestone(id: 'ms_36_l1', ageMonths: 36, domain: DevDomain.language,
      title: 'Uses at least 2 back-and-forth exchanges in conversation'),
  DevMilestone(id: 'ms_36_l2', ageMonths: 36, domain: DevDomain.language,
      title: 'Asks "who", "what", "where", or "why" questions'),
  DevMilestone(id: 'ms_36_l3', ageMonths: 36, domain: DevDomain.language,
      title: 'Says what action is happening in a picture'),
  DevMilestone(id: 'ms_36_l4', ageMonths: 36, domain: DevDomain.language,
      title: 'Says first name when asked'),
  DevMilestone(id: 'ms_36_l5', ageMonths: 36, domain: DevDomain.language,
      title: 'Talks well enough for others to understand most of the time'),
  DevMilestone(id: 'ms_36_c1', ageMonths: 36, domain: DevDomain.cognitive,
      title: 'Draws a circle when you show them how'),
  DevMilestone(id: 'ms_36_c2', ageMonths: 36, domain: DevDomain.cognitive,
      title: 'Avoids touching hot objects after being warned'),
  DevMilestone(id: 'ms_36_m1', ageMonths: 36, domain: DevDomain.motor,
      title: 'Strings items together (large beads on a string)'),
  DevMilestone(id: 'ms_36_m2', ageMonths: 36, domain: DevDomain.motor,
      title: 'Puts on some clothes by themselves'),
  DevMilestone(id: 'ms_36_m3', ageMonths: 36, domain: DevDomain.motor,
      title: 'Uses a fork'),

  // ── 48 months (4 years) ─────────────────────────────────────────────────────
  DevMilestone(id: 'ms_48_s1', ageMonths: 48, domain: DevDomain.social,
      title: 'Pretends to be something else during play (teacher, superhero)'),
  DevMilestone(id: 'ms_48_s2', ageMonths: 48, domain: DevDomain.social,
      title: 'Asks to go play with children if none are around'),
  DevMilestone(id: 'ms_48_s3', ageMonths: 48, domain: DevDomain.social,
      title: 'Comforts others who are hurt or sad'),
  DevMilestone(id: 'ms_48_s4', ageMonths: 48, domain: DevDomain.social,
      title: 'Avoids danger (doesn\'t jump from tall heights)'),
  DevMilestone(id: 'ms_48_s5', ageMonths: 48, domain: DevDomain.social,
      title: 'Changes behavior based on where they are (library vs. playground)'),
  DevMilestone(id: 'ms_48_l1', ageMonths: 48, domain: DevDomain.language,
      title: 'Says sentences with 4 or more words'),
  DevMilestone(id: 'ms_48_l2', ageMonths: 48, domain: DevDomain.language,
      title: 'Says some words from a song, story, or nursery rhyme'),
  DevMilestone(id: 'ms_48_l3', ageMonths: 48, domain: DevDomain.language,
      title: 'Talks about at least one thing that happened during their day'),
  DevMilestone(id: 'ms_48_l4', ageMonths: 48, domain: DevDomain.language,
      title: 'Answers simple questions'),
  DevMilestone(id: 'ms_48_c1', ageMonths: 48, domain: DevDomain.cognitive,
      title: 'Names a few colors of items'),
  DevMilestone(id: 'ms_48_c2', ageMonths: 48, domain: DevDomain.cognitive,
      title: 'Tells what comes next in a well-known story'),
  DevMilestone(id: 'ms_48_c3', ageMonths: 48, domain: DevDomain.cognitive,
      title: 'Draws a person with 3 or more body parts'),
  DevMilestone(id: 'ms_48_m1', ageMonths: 48, domain: DevDomain.motor,
      title: 'Catches a large ball most of the time'),
  DevMilestone(id: 'ms_48_m2', ageMonths: 48, domain: DevDomain.motor,
      title: 'Serves themselves food or pours water with supervision'),
  DevMilestone(id: 'ms_48_m3', ageMonths: 48, domain: DevDomain.motor,
      title: 'Unbuttons some buttons'),
  DevMilestone(id: 'ms_48_m4', ageMonths: 48, domain: DevDomain.motor,
      title: 'Holds crayon or pencil between fingers and thumb'),

  // ── 60 months (5 years) ─────────────────────────────────────────────────────
  DevMilestone(id: 'ms_60_s1', ageMonths: 60, domain: DevDomain.social,
      title: 'Follows rules or takes turns when playing games'),
  DevMilestone(id: 'ms_60_s2', ageMonths: 60, domain: DevDomain.social,
      title: 'Sings, dances, or acts for you'),
  DevMilestone(id: 'ms_60_s3', ageMonths: 60, domain: DevDomain.social,
      title: 'Does simple chores at home (matching socks, clearing table)'),
  DevMilestone(id: 'ms_60_s4', ageMonths: 60, domain: DevDomain.social,
      title: 'Is careful near hot objects and other dangers'),
  DevMilestone(id: 'ms_60_l1', ageMonths: 60, domain: DevDomain.language,
      title: 'Tells a story with at least 2 events'),
  DevMilestone(id: 'ms_60_l2', ageMonths: 60, domain: DevDomain.language,
      title: 'Answers simple questions about a book or story'),
  DevMilestone(id: 'ms_60_l3', ageMonths: 60, domain: DevDomain.language,
      title: 'Keeps a conversation going with 3+ back-and-forth exchanges'),
  DevMilestone(id: 'ms_60_l4', ageMonths: 60, domain: DevDomain.language,
      title: 'Uses or recognises simple rhymes (bat-cat, ball-fall)'),
  DevMilestone(id: 'ms_60_c1', ageMonths: 60, domain: DevDomain.cognitive,
      title: 'Counts to 10'),
  DevMilestone(id: 'ms_60_c2', ageMonths: 60, domain: DevDomain.cognitive,
      title: 'Names some numbers between 1 and 5 when shown'),
  DevMilestone(id: 'ms_60_c3', ageMonths: 60, domain: DevDomain.cognitive,
      title: 'Uses words about time (yesterday, tomorrow, morning, night)'),
  DevMilestone(id: 'ms_60_c4', ageMonths: 60, domain: DevDomain.cognitive,
      title: 'Pays attention for 5 to 10 minutes during activities'),
  DevMilestone(id: 'ms_60_c5', ageMonths: 60, domain: DevDomain.cognitive,
      title: 'Writes some letters in their name'),
  DevMilestone(id: 'ms_60_m1', ageMonths: 60, domain: DevDomain.motor,
      title: 'Buttons some buttons'),
  DevMilestone(id: 'ms_60_m2', ageMonths: 60, domain: DevDomain.motor,
      title: 'Hops on one foot'),
];

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Milestones for a specific age group, grouped by domain in display order.
Map<DevDomain, List<DevMilestone>> cdcByAgeAndDomain(int ageMonths) {
  final items = cdcMilestones.where((m) => m.ageMonths == ageMonths).toList();
  return {
    for (final domain in DevDomain.values)
      domain: items.where((m) => m.domain == domain).toList(),
  };
}

/// The age group (in months) the child currently falls into, or null if older
/// than 5 years.
int? currentAgeGroup(DateTime dob) {
  final ageMonths = DateTime.now().difference(dob).inDays ~/ 30;
  for (int i = cdcAgeGroups.length - 1; i >= 0; i--) {
    if (ageMonths >= cdcAgeGroups[i]) return cdcAgeGroups[i];
  }
  return cdcAgeGroups.first;
}
