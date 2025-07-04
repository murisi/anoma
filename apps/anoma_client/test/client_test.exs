defmodule Anoma.ClientTest do
  # these tests cannot run async
  # they require the grpc proxy and there can only be one instance of this at a time.
  use ExUnit.Case, async: false

  use TestHelper.GenerateExampleTests,
    for: Anoma.Client.Examples.EClient.Intents

  use TestHelper.GenerateExampleTests,
    for: Anoma.Client.Examples.EClient.Mempool

  use TestHelper.GenerateExampleTests,
    for: Anoma.Client.Examples.EClient.Nock

  use TestHelper.GenerateExampleTests,
    for: Anoma.Client.Examples.EClient.Executor

  use TestHelper.GenerateExampleTests,
    for: Anoma.Client.Examples.EClient.Nock.Scry

  use TestHelper.GenerateExampleTests,
    for: Anoma.Client.Examples.EClient.Nock.Run

  use TestHelper.GenerateExampleTests,
    for: Anoma.Client.Examples.EClient.Nock.Prove
end
