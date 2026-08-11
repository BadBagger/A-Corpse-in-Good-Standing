using System.Text.Json;
using System.Text.Json.Serialization;

namespace Corpse.Duels;

public static class DuelContent
{
    private static readonly JsonSerializerOptions Options = new()
    {
        PropertyNameCaseInsensitive = true,
        Converters = { new JsonStringEnumConverter() }
    };

    public static IReadOnlyList<Confession> LoadConfessions(string path)
    {
        var json = File.ReadAllText(path);
        var items = JsonSerializer.Deserialize<List<ConfessionDto>>(json, Options)
            ?? throw new InvalidDataException($"No confessions found in {path}.");
        return items.Select(item => new Confession(
            item.Id,
            item.Text,
            item.Elaboration,
            item.Category,
            item.Weight,
            item.ActAvailable,
            item.Acquisition)).ToList();
    }

    public static Opponent LoadOpponent(string path)
    {
        var json = File.ReadAllText(path);
        var item = JsonSerializer.Deserialize<OpponentDto>(json, Options)
            ?? throw new InvalidDataException($"No opponent found in {path}.");
        return new Opponent(
            item.Id,
            item.Name,
            item.ActAvailable,
            item.Attacks.Select(attack => new Attack(
                attack.Id,
                attack.Text,
                attack.Category,
                attack.Weight,
                attack.LocksConfessionId)).ToList());
    }

    private sealed record ConfessionDto(
        string Id,
        string Text,
        string Elaboration,
        SinCategory Category,
        int Weight,
        [property: JsonPropertyName("act_available")] int ActAvailable,
        string Acquisition);

    private sealed record OpponentDto(
        string Id,
        string Name,
        [property: JsonPropertyName("act_available")] int ActAvailable,
        List<AttackDto> Attacks);

    private sealed record AttackDto(
        string Id,
        string Text,
        SinCategory Category,
        int Weight,
        [property: JsonPropertyName("locks_confession_id")] string? LocksConfessionId);
}
