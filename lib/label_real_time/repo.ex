defmodule LabelRealTime.Repo do
  use Ecto.Repo,
    otp_app: :label_real_time,
    adapter: Ecto.Adapters.Postgres
end
