defmodule LabelRealTimeWeb.LabellingLive do
  use LabelRealTimeWeb, :live_view

  alias LabelRealTime.Images
  alias LabelRealTimeWeb.Presence
  alias LabelRealTime.CircleDrawer
  import LabelRealTime.Colors

  @topic "cursorview"

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
    # Split email from current_user to get username
    user =
      current_user.email
      |> String.split("@")
      |> hd()

    # Make a random color for a given user
    color = make_HSL_color(current_user.email)

    if connected?(socket) do
      {:ok, _reference} =
        Presence.track(self(), @topic, socket.id, %{
          socket_id: socket.id,
          x: 50,
          y: 50,
          message: "",
          name: user,
          color: color,
          canvas: CircleDrawer.new_canvas()
        })
    end

    Phoenix.PubSub.subscribe(LabelRealTime.PubSub, @topic)

    # List of presences
    initial_users =
      Presence.list(@topic)
      |> Enum.map(fn {_, data} -> data[:metas] |> List.first() end)

    # {:ok,
    #  assign(socket,
    #    images: images,
    #    current: 0,
    #    is_playing: false,
    #    timer: nil,
    #    x: 50,
    #    y: 50,
    #    user: user
    #  )}

    socket =
      socket
      |> assign(:images, images)
      |> assign(:current, 0)
      |> assign(:is_playing, false)
      |> assign(:timer, nil)
      |> assign(:user, user)
      |> assign(:users, initial_users)
      |> assign(:socket_id, socket.id)
      |> assign(:canvas, CircleDrawer.new_canvas())

    {:ok, socket}
  end

  def handle_event("save-img", _unsigned_params, socket) do
    # Inspect socket
    IO.inspect(socket, label: "socket values")
    # Get X and Y coordinates from two circles drawn
    my_x1 = Enum.at(socket.assigns.canvas.circles, 1).x |> trunc()
    my_y1 = Enum.at(socket.assigns.canvas.circles, 1).y |> trunc()
    my_x2 = Enum.at(socket.assigns.canvas.circles, 0).x |> trunc()
    my_y2 = Enum.at(socket.assigns.canvas.circles, 0).y |> trunc()
    # Get row and column ranges in a format required by Evision.Mat.roi()
    row_range = {my_y1, my_y2}
    column_range = {my_x1, my_x2}

    # Inspect circles, coordinates, and ranges
    # IO.inspect(socket.assigns.canvas.circles, label: "My-circles:")
    # IO.inspect(my_x1, label: "My-X1:")
    # IO.inspect(my_y1, label: "My-Y1:")
    # IO.inspect(my_x2, label: "My-X2:")
    # IO.inspect(my_y2, label: "My-Y2:")
    # IO.inspect(row_range, label: "Row range:")
    # IO.inspect(column_range, label: "Column range:")

    # Read image from file
    images = socket.assigns.images
    {image_url, _} = List.pop_at(images, socket.assigns.current)
    # IO.inspect(image_url, label: "Image_URL:")

    # Read current image
    current_image = Evision.imread("priv/static" <> image_url)
    # IO.inspect(current_image)

    # select a roi, we can do it in several ways
    # remember that ranges in Elixir are inclusive
    # dog_roi = current_image[[50..130, 80..150]]
    # dog_roi = Evision.Mat.roi(current_image, {my_x1, my_y1, 60, 60})
    image_roi = Evision.Mat.roi(current_image, row_range, column_range)
    # IO.inspect(dog_roi)

    # Write roi to file
    # Note: I don't know why the liveview is restarting/reseting when Evision.imwrite() executes
    Evision.imwrite("priv/static/images/small_dog.jpeg", image_roi)

    {:noreply, socket}
  end

  def handle_event("canvas-click", %{"x" => x, "y" => y}, socket) do
    canvas = socket.assigns.canvas
    key = socket.id
    # payload = %{x: x, y: y}

    circle = CircleDrawer.new_circle(x, y)
    updated_canvas = CircleDrawer.add_circle(canvas, circle)

    payload = %{canvas: updated_canvas}
    updatePresence(key, payload)

    socket =
      socket
      |> assign(:canvas, updated_canvas)

    {:noreply, socket}
  end

  def handle_event("cursor-move", %{"x" => x, "y" => y}, socket) do
    key = socket.id
    payload = %{x: x, y: y}
    updatePresence(key, payload)
    {:noreply, socket}
  end

  def handle_event("send_message", %{"message" => message}, socket) do
    # IO.inspect(socket.assigns)

    # # Read image from file
    # current_image = Evision.imread("priv/static/images/dog.jpeg")
    # # Inspect current_image
    # IO.inspect(current_image)

    # # select a roi
    # dog_roi = current_image[[50..130, 80..150]]
    # # Inspect roi
    # IO.inspect(dog_roi)

    # # Write roi to file
    # Evision.imwrite("priv/static/images/small_dog.jpeg", dog_roi)

    updatePresence(socket.id, %{message: message})
    {:noreply, socket}
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

  def handle_info(%{event: "presence_diff", payload: _payload}, socket) do
    users =
      Presence.list(@topic)
      |> Enum.map(fn {_, data} -> data[:metas] |> List.first() end)

    socket =
      socket
      |> assign(users: users)
      |> assign(socket_id: socket.id)

    {:noreply, socket}
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

  def updatePresence(key, payload) do
    metas =
      Presence.get_by_key(@topic, key)[:metas]
      |> List.first()
      |> Map.merge(payload)

    Presence.update(self(), @topic, key, metas)
  end
end
