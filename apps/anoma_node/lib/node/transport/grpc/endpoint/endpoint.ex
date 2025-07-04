# Define your endpoint
defmodule Anoma.Node.Transport.GRPC.Endpoint do
  use GRPC.Endpoint

  intercept(GRPC.Server.Interceptors.Logger)
  intercept(GRPC.Server.Interceptors.NockErrors)
  run(Anoma.Node.Transport.GRPC.Servers.Intents)
  run(Anoma.Node.Transport.GRPC.Servers.Mempool)
  run(Anoma.Node.Transport.GRPC.Servers.Executor)
  run(Anoma.Node.Transport.GRPC.Servers.Advertisement)
  run(Anoma.Node.Transport.GRPC.Servers.IntraNode)
  run(Anoma.Node.Transport.GRPC.Servers.PubSub)
end
