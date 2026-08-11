namespace Corpse.Narrative;

public static class PrologueJournalCatalog
{
    public static IReadOnlyList<JournalEntry> Entries { get; } =
    [
        new(
            "j_returned_nine_days",
            "Nine Days",
            "The returned get nine days before the salt finishes its work."),
        new(
            "j_somebody_drowned_corvin",
            "Not An Accident",
            "Tomas says nobody drowns by accident in Mordida harbor."),
        new(
            "j_corvin_died_thursday",
            "Thursday",
            "Corvin was pulled from the harbor on Thursday. That leaves six days.")
    ];
}

