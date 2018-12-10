defmodule MitbitsCryptocurrencyWebWeb.HelloController do

  use MitbitsCryptocurrencyWebWeb, :controller

#  def handle_info(:kickoff, {}) do
#    numNodes = 20
#    numMiners = 5
#    :ets.new(:mitbits, [:set, :public, :named_table])
#
#    {numNodes, numMiners}
#    |> spawn_miners()
#    |> create_genesis_block()
#    |> spawn_miner_nodes()
#    |> spawn_nodes()
#    |> start_mining()
#    |> make_transactions()
#
#    #  assert 1+1 == 1
#
#    {:noreply, {}}
#  end

  def spawn_miners({numNodes, numMiners}) do
    miner_pk_hash_sk =
      Enum.map(1..numMiners, fn _ ->
        {:ok, {sk, pk}} = RsaEx.generate_keypair()
        hash_name = Mitbits.Utility.getHash(pk)
        {:ok, _} = Mitbits.MinerSupervisor.add_miner(pk, sk, hash_name)
        {pk, hash_name, sk}
      end)

    miners =
      Enum.map(miner_pk_hash_sk, fn {_, hash_name, _} ->
        {hash_name}
      end)

    :ets.insert(:mitbits, {"miners", miners})
    {miner_pk_hash_sk, numNodes, numMiners}
  end

  def create_genesis_block({miner_pk_hash_sk, numNodes, numMiners}) do
    [{_, first_miner_hash, _} | _] = miner_pk_hash_sk

    {genesis_block} =
      GenServer.call(
        Mitbits.Utility.string_to_atom("miner_" <> first_miner_hash),
        {:mine_first, "thefoxjkfsndaljd"}
      )

    :ets.insert(:mitbits, {"prev_block_hash", genesis_block.hash})
    {genesis_block, miner_pk_hash_sk, numNodes, numMiners}
  end

  def spawn_miner_nodes({genesis_block, miner_pk_hash_sk, numNodes, numMiners}) do
    miner_node_hash =
      Enum.map(miner_pk_hash_sk, fn {pk, hash_name, sk} ->
        {:ok, _} = Mitbits.NodeSupervisor.add_node(pk, sk, genesis_block, hash_name)

        {:ok} =
          GenServer.call(Mitbits.Utility.string_to_atom("node_" <> hash_name), :update_wallet)

        {:ok} =
          GenServer.call(
            Mitbits.Utility.string_to_atom("node_" <> hash_name),
            :add_latest_block_to_indexded_blockchain
          )

        {hash_name}
      end)

    {genesis_block, miner_node_hash, miner_pk_hash_sk, numNodes, numMiners}
  end

  def spawn_nodes({genesis_block, miner_node_hash, miner_pk_hash_sk, numNodes, numMiners}) do
    [{_, first_miner_hash, _} | _] = miner_pk_hash_sk

    node_hash =
      Enum.map(1..numNodes, fn _ ->
        {:ok, {sk, pk}} = RsaEx.generate_keypair()
        hash_name = Mitbits.Utility.getHash(pk)

        if(hash_name != miner_node_hash) do
          {:ok, _} = Mitbits.NodeSupervisor.add_node(pk, sk, genesis_block, hash_name)

          {:ok} =
            GenServer.call(
              Mitbits.Utility.string_to_atom("node_" <> hash_name),
              :add_latest_block_to_indexded_blockchain
            )
        end

        {hash_name}
      end)

    all_nodes = miner_node_hash ++ node_hash

    # IO.inspect(node_hash)
    :ets.insert(:mitbits, {"nodes", all_nodes})

    Enum.each(node_hash, fn {hash} ->
      GenServer.cast(
        Mitbits.Utility.string_to_atom("node_" <> first_miner_hash),
        {:req_for_mitbits, 10, hash}
      )
    end)

    {node_hash, miner_node_hash, miner_pk_hash_sk, numNodes, numMiners}
  end

  def start_mining({node_hash, miner_node_hash, miner_pk_hash_sk, numNodes, numMiners}) do
    acc =
      Enum.reduce(miner_pk_hash_sk, 0, fn {_, miner_hash, _}, acc ->
        Mitbits.Miner.start_mining(miner_hash)
        acc + 1
      end)

    {acc, node_hash, miner_node_hash, miner_pk_hash_sk, numNodes, numMiners}
  end

  def make_transactions({acc, node_hash, miner_node_hash, miner_pk_hash_sk, numNodes, numMiners}) do
    [{_, all_nodes}] = :ets.lookup(:mitbits, "nodes")

    Enum.each(1..(acc * 2000), fn i ->
      {node1_hash} = Enum.random(all_nodes)
      {node2_hash} = Enum.random(all_nodes)
      amount = Enum.random(1..10)

      GenServer.cast(
        Mitbits.Utility.string_to_atom("node_" <> node1_hash),
        {:req_for_mitbits, amount, node2_hash}
      )
    end)
  end

  def index(conn, _params) do

    render(conn, "index.html")
  end

#  def simulator(conn, _params) do
#    #MitbitsCryptocurrencyWeb.Application.start(:normal)
#
#    [{_, all_nodes}] = :ets.lookup(:MitbitsCryptocurrencyWeb, "nodes")
#
#    Enum.each(1..(acc * 2000), fn i ->
#      {node1_hash} = Enum.random(all_nodes)
#      {node2_hash} = Enum.random(all_nodes)
#      amount = Enum.random(1..10)
#
#      GenServer.cast(
#        MitbitsCryptocurrencyWeb.Utility.string_to_atom("node_" <> node1_hash),
#        {:req_for_MitbitsCryptocurrencyWeb, amount, node2_hash}
#      )
#    end)
#
#    render(conn, "startup.html")
#  end

#  def show(conn, %{"messenger" => messenger}) do
#    render(conn, "show.html", messenger: messenger)
#  end


  def show(conn, _params) do
    [{_, all_nodes}] = :ets.lookup(:MitbitsCryptocurrencyWeb, "nodes")


    render(conn, "show.html", messenger: all_nodes)
  end


  def account(conn, %{"participant" => participant}) do

    balance = MitbitsCryptocurrencyWeb.Node.get_balance(participant)
    [{_, all_nodes}] = :ets.lookup(:MitbitsCryptocurrencyWeb, "nodes")

    other_nodes = all_nodes -- [participant]
    render(conn, "account.html", balance: balance,participant: participant, nodes: other_nodes)
  end

  def create(conn, params) do

    participant = Map.get(params, "participant")
    to = Map.get(params,"to")
    amount = Map.get(params, "amount")

    GenServer.cast(
      MitbitsCryptocurrencyWeb.Utility.string_to_atom("node_" <> participant),
      {:req_for_MitbitsCryptocurrencyWeb, amount, to}
    )

    render(conn, "txn.html", participant: participant, to: to, amount: amount);

  end

  def blockchain(conn, params) do

    [{_, node_hash}] = :ets.lookup(:MitbitsCryptocurrencyWeb, "nodes")

    {first} = Enum.at(node_hash, 0)
    {blockchain} =
      GenServer.call(MitbitsCryptocurrencyWeb.Utility.string_to_atom("node_" <> first), :get_blockchain)

    render(conn, "blockchain.html", blockchain: blockchain);

  end

  def stats(conn, params) do

    [{_,data}] = :ets.lookup(:MitbitsCryptocurrencyWeb, "time_blockchain")

    [{_, node_hash}] = :ets.lookup(:MitbitsCryptocurrencyWeb, "nodes")

    {first} = Enum.at(node_hash, 0)

    indexed_blockchain =
        GenServer.call(MitbitsCryptocurrencyWeb.Utility.string_to_atom("node_" <> first), :get_indexed_blockchain)

    render(conn, "stat.html", data: data, indexed_blockchain: indexed_blockchain);

  end

  def createTxn(conn, params) do

    [{_, all_nodes}] = :ets.lookup(:MitbitsCryptocurrencyWeb, "nodes")


    Enum.each(1..(5 * 2000), fn i ->
      {node1_hash} = Enum.random(all_nodes)
      {node2_hash} = Enum.random(all_nodes)
      amount = Enum.random(1..10)

      GenServer.cast(
        MitbitsCryptocurrencyWeb.Utility.string_to_atom("node_" <> node1_hash),
        {:req_for_MitbitsCryptocurrencyWeb, amount, node2_hash}
      )
    end)

    render(conn, "random.html");

  end
end
