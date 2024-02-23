defmodule LabelRealTimeWeb.LabellingLive do
  use LabelRealTimeWeb, :live_view
  alias LabelRealTime.Images

  def mount(_params, _session, socket) do
    # Get all images from DB and make a list of images
    images =
      Images.list_images()
      |> Enum.map(fn image -> image.image_locations end)
      |> List.flatten()

    # img =
    #   0..18
    #   |> Enum.map(&String.pad_leading("#{&1}", 2, "0"))
    #   |> Enum.map(&"juggling-#{&1}.jpg")

    # IO.inspect(images)
    # IO.inspect(socket.assigns)
    # IO.inspect(session)

    # Get current user
    %{current_user: current_user} = socket.assigns
    # Split email to get username
    user =
      current_user.email
      |> String.split("@")
      |> hd()

    {:ok,
     assign(socket,
       images: images,
       current: 0,
       is_playing: false,
       timer: nil,
       x: 50,
       y: 50,
       user: user
     )}
  end

  def handle_event("cursor-move", %{"x" => x, "y" => y}, socket) do
    updated =
      socket
      |> assign(:x, x)
      |> assign(:y, y)

    {:noreply, updated}
  end

  def handle_event("set-current", %{"key" => "Enter", "value" => value}, socket) do
    {:noreply, assign(socket, :current, String.to_integer(value))}
  end

  def handle_event("update", %{"key" => "k"}, socket) do
    {:noreply, toggle_playing(socket)}
  end

  def handle_event("update", %{"key" => "ArrowRight"}, socket) do
    {:noreply, assign(socket, :current, next(socket))}
  end

  def handle_event("update", %{"key" => "ArrowLeft"}, socket) do
    {:noreply, assign(socket, :current, previous(socket))}
  end

  def handle_event("update", _, socket) do
    {:noreply, socket}
  end

  def handle_event("toggle-playing", _, socket) do
    {:noreply, toggle_playing(socket)}
  end

  def handle_info(:tick, socket) do
    {:noreply, assign(socket, :current, next(socket))}
  end

  def toggle_playing(socket) do
    socket = update(socket, :is_playing, fn playing -> !playing end)

    if socket.assigns.is_playing do
      {:ok, timer} = :timer.send_interval(2000, self(), :tick)
      assign(socket, :timer, timer)
    else
      {:ok, _} = :timer.cancel(socket.assigns.timer)
      assign(socket, :timer, nil)
    end
  end

  def next(socket) do
    %{current: current, images: images} = socket.assigns

    rem(current + 1, Enum.count(images))
  end

  def previous(socket) do
    %{current: current, images: images} = socket.assigns

    rem(current - 1 + Enum.count(images), Enum.count(images))
  end
end
