defmodule LabelRealTime.Colors do
  @doc """
  Make a random HSL color for a given string
  """
  def make_HSL_color(s) do
    hue =
      to_charlist(s)
      |> Enum.sum()
      |> :rand.uniform()
      |> rem(360)

    "hsl(#{hue}, 70%, 40%)"
  end
end
