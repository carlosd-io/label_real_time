defmodule LabelRealTime.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LabelRealTimeWeb.Telemetry,
      LabelRealTime.Repo,
      {DNSCluster, query: Application.get_env(:label_real_time, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LabelRealTime.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: LabelRealTime.Finch},
      # Start a worker by calling: LabelRealTime.Worker.start_link(arg)
      # {LabelRealTime.Worker, arg},
      # Start to serve requests, typically the last entry
      LabelRealTimeWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LabelRealTime.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LabelRealTimeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
