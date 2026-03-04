// Wird von spell.dart, ability.dart und zukünftigen Modellen importiert.

// Welches Attribut löst einen Rettungswurf aus?
enum SavingThrowAttribute {
  none,
  strength,
  dexterity,
  constitution,
  intelligence,
  wisdom,
  charisma,
}

// Welches Attribut wird als Zauberattribut genutzt?
// (Magier = Intelligenz, Kleriker = Weisheit, Barde = Charisma usw.)
enum SpellcastingAttribute {
  intelligence,
  wisdom,
  charisma,
}