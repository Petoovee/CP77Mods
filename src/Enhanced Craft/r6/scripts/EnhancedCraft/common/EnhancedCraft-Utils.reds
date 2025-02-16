module EnhancedCraft.Common

// -- Checks if item with id has iconic flag defined in TweakXL
public static func IsPresetIconic(id: TweakDBID) -> Bool {
  let variant: Variant = TweakDBInterface.GetFlat(id + t".iconicVariant");
  let isIconic: Bool = FromVariant<Bool>(variant);
  return isIconic;
}

// -- Checks if item has DLC jackets variations
public static func HasDLCItems(id: TweakDBID) -> Bool {
  let variant: Variant = TweakDBInterface.GetFlat(id + t".hasDLCItems");
  let hasItems: Bool = FromVariant<Bool>(variant);
  return hasItems;
}

// -- Get quality representation as int value to bind with the one defined in IconicRecipeCondition
public static func GetBaseQualityValue(quality: CName) -> Int32  {
  switch (quality) {
    case n"Rare": return 1;
    case n"Epic": return 2;
    case n"Legendary": return 3;
  };

  return 0;
}

// -- Basic logging function
public static func L(str: String) -> Void {
  // LogChannel(n"DEBUG", s"Craft: \(str)");
}
