defmodule Anoma.Node.Examples.ELogging do
  alias Anoma.Node
  alias Anoma.Node.Examples.ENode
  alias Anoma.Node.Tables
  alias Anoma.Node.Transaction.Backends
  alias Anoma.Node.Transaction.Mempool

  require ExUnit.Assertions
  require Node.Event

  import ExUnit.Assertions

  use EventBroker.WithSubscription

  @spec check_tx_event(String.t()) :: String.t()
  def check_tx_event(node_id \\ Node.example_random_id()) do
    ENode.start_node(node_id: node_id)
    table_name = Tables.table_events(node_id)

    :mnesia.subscribe({:table, table_name, :simple})

    tx_event("id 1", :transparent_resource, "code 1", node_id)

    assert_receive(
      {:mnesia_table_event,
       {:write, {_, "id 1", {:transparent_resource, "code 1"}}, _}},
      5000
    )

    assert {:atomic,
            [{^table_name, "id 1", {:transparent_resource, "code 1"}}]} =
             :mnesia.transaction(fn ->
               :mnesia.read(table_name, "id 1")
             end)

    # unsubscribing breaks nested example calls.
    # :mnesia.unsubscribe({:table, table_name, :simple})
    node_id
  end

  @spec check_multiple_tx_events(String.t()) :: String.t()
  def check_multiple_tx_events(node_id \\ Node.example_random_id()) do
    ENode.start_node(node_id: node_id)

    table_name = Tables.table_events(node_id)

    :mnesia.subscribe({:table, table_name, :simple})

    tx_event("id 1", :transparent_resource, "code 1", node_id)
    tx_event("id 2", :transparent_resource, "code 2", node_id)

    assert_receive(
      {:mnesia_table_event,
       {:write, {^table_name, "id 1", {:transparent_resource, "code 1"}}, _}},
      5000
    )

    assert_receive(
      {:mnesia_table_event,
       {:write, {^table_name, "id 2", {:transparent_resource, "code 2"}}, _}},
      5000
    )

    assert {:atomic,
            [{^table_name, "id 1", {:transparent_resource, "code 1"}}]} =
             :mnesia.transaction(fn ->
               :mnesia.read(table_name, "id 1")
             end)

    assert {:atomic,
            [{^table_name, "id 2", {:transparent_resource, "code 2"}}]} =
             :mnesia.transaction(fn ->
               :mnesia.read(table_name, "id 2")
             end)

    # unsubscribing breaks nested example calls.
    # :mnesia.unsubscribe({:table, table_name, :simple})
    node_id
  end

  ############################################################
  #                      Consensus event                     #
  ############################################################

  @spec check_consensus_event(String.t()) :: String.t()
  def check_consensus_event(
        node_id \\ Node.example_random_id()
        |> Base.url_encode64()
      ) do
    check_tx_event(node_id)
    table_name = Tables.table_events(node_id)

    :mnesia.subscribe({:table, table_name, :simple})

    consensus_event(["id 1"], node_id)

    assert_receive(
      {:mnesia_table_event,
       {:write, {^table_name, :consensus, [["id 1"]]}, _}},
      5000
    )

    # unsubscribing breaks nested example calls.
    # :mnesia.unsubscribe({:table, table_name, :simple})

    assert {:atomic, [{^table_name, :consensus, [["id 1"]]}]} =
             :mnesia.transaction(fn ->
               :mnesia.read(table_name, :consensus)
             end)

    node_id
  end

  @spec check_consensus_event_multiple(String.t()) :: String.t()
  def check_consensus_event_multiple(
        node_id \\ Node.example_random_id()
        |> Base.url_encode64()
      ) do
    check_multiple_tx_events(node_id)
    table_name = Tables.table_events(node_id)

    :mnesia.subscribe({:table, table_name, :simple})

    consensus_event(["id 1"], node_id)
    consensus_event(["id 2"], node_id)

    assert_receive(
      {:mnesia_table_event,
       {:write, {^table_name, :consensus, [["id 1"], ["id 2"]]}, _}},
      5000
    )

    # unsubscribing breaks nested example calls.
    # :mnesia.unsubscribe({:table, table_name, :simple})

    assert {:atomic, [{^table_name, :consensus, [["id 1"], ["id 2"]]}]} =
             :mnesia.transaction(fn ->
               :mnesia.read(table_name, :consensus)
             end)

    node_id
  end

  ############################################################
  #                         Block event                      #
  ############################################################

  @spec check_block_event(String.t()) :: String.t()
  def check_block_event(
        node_id \\ Node.example_random_id()
        |> Base.url_encode64()
      ) do
    check_consensus_event(node_id)
    table_name = Tables.table_events(node_id)

    :mnesia.subscribe({:table, table_name, :simple})

    block_event(["id 1"], 0, node_id)

    assert_receive(
      {:mnesia_table_event, {:delete, {^table_name, "id 1"}, _}},
      5000
    )

    # unsubscribing breaks nested example calls.
    # :mnesia.unsubscribe({:table, table_name, :simple})

    assert {:atomic, [{^table_name, :consensus, []}]} =
             :mnesia.transaction(fn ->
               :mnesia.read(table_name, :consensus)
             end)

    assert {:atomic, []} =
             :mnesia.transaction(fn ->
               :mnesia.read(table_name, "id 1")
             end)

    node_id
  end

  @spec check_block_event_multiple(String.t()) :: String.t()
  def check_block_event_multiple(
        node_id \\ Node.example_random_id()
        |> Base.url_encode64()
      ) do
    check_consensus_event_multiple(node_id)
    table_name = Tables.table_events(node_id)

    :mnesia.subscribe({:table, table_name, :simple})
    block_event(["id 1"], 0, node_id)

    assert_receive(
      {:mnesia_table_event, {:delete, {^table_name, "id 1"}, _}},
      5000
    )

    assert {:atomic, [{^table_name, :consensus, [["id 2"]]}]} =
             :mnesia.transaction(fn ->
               :mnesia.read(table_name, :consensus)
             end)

    assert {:atomic, []} =
             :mnesia.transaction(fn ->
               :mnesia.read(table_name, "id 1")
             end)

    block_event(["id 2"], 0, node_id)

    assert_receive(
      {:mnesia_table_event, {:delete, {^table_name, "id 2"}, _}},
      5000
    )

    # unsubscribing breaks nested example calls.
    # :mnesia.unsubscribe({:table, table_name, :simple})

    assert {:atomic, [{^table_name, :consensus, []}]} =
             :mnesia.transaction(fn ->
               :mnesia.read(table_name, :consensus)
             end)

    assert {:atomic, []} =
             :mnesia.transaction(fn ->
               :mnesia.read(table_name, "id 2")
             end)

    node_id
  end

  @spec check_block_event_leave_one_out(String.t()) :: String.t()
  def check_block_event_leave_one_out(
        node_id \\ Node.example_random_id()
        |> Base.url_encode64()
      ) do
    check_consensus_event_multiple(node_id)
    table_name = Tables.table_events(node_id)

    :mnesia.subscribe({:table, table_name, :simple})
    block_event(["id 1"], 0, node_id)

    assert_receive(
      {:mnesia_table_event, {:delete, {^table_name, "id 1"}, _}},
      5000
    )

    # unsubscribing breaks nested example calls.
    # :mnesia.unsubscribe({:table, table_name, :simple})

    assert {:atomic, [{^table_name, :consensus, [["id 2"]]}]} =
             :mnesia.transaction(fn ->
               :mnesia.read(table_name, :consensus)
             end)

    assert {:atomic, []} =
             :mnesia.transaction(fn ->
               :mnesia.read(table_name, "id 1")
             end)

    assert {:atomic,
            [{^table_name, "id 2", {:transparent_resource, "code 2"}}]} =
             :mnesia.transaction(fn ->
               :mnesia.read(table_name, "id 2")
             end)

    node_id
  end

  @spec write_consensus(String.t()) :: atom()
  def write_consensus(node_id) do
    table = write_tx(node_id)

    :mnesia.transaction(fn ->
      :mnesia.write({table, :consensus, [["id 1"]]})
    end)

    table
  end

  @spec write_tx(String.t()) :: atom()
  defp write_tx(node_id) do
    table = create_event_table(node_id)

    :mnesia.transaction(fn ->
      :mnesia.write({table, "id 1", {:debug_bloblike, "code 1"}})
    end)

    table
  end

  @spec create_event_table(String.t()) :: atom()
  defp create_event_table(node_id) do
    table = Tables.table_events(node_id)
    :mnesia.create_table(table, attributes: [:type, :body])

    :mnesia.transaction(fn ->
      :mnesia.write({table, :round, -1})
    end)

    table
  end

  @spec tx_event(binary(), Backends.backend(), Noun.t(), String.t()) :: :ok
  def tx_event(id, backend, code, node_id) do
    event =
      Node.Event.new_with_body(node_id, %Mempool.Events.TxEvent{
        id: id,
        tx: %Mempool.Tx{backend: backend, code: code}
      })

    EventBroker.event(event)
  end

  @spec consensus_event(list(binary()), String.t()) :: :ok
  def consensus_event(order, node_id) do
    event =
      Node.Event.new_with_body(node_id, %Mempool.Events.ConsensusEvent{
        order: order
      })

    EventBroker.event(event)
  end

  @spec block_event(list(binary()), non_neg_integer(), String.t()) :: :ok
  def block_event(order, round, node_id) do
    event =
      Node.Event.new_with_body(node_id, %Mempool.Events.BlockEvent{
        order: order,
        round: round
      })

    EventBroker.event(event)
  end
end
