defmodule MitbitsCryptocurrencyWeb.Driver do
  use GenServer
  # use ExUnit.Case
  @me __MODULE__

  # API
  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args, name: @me)
  end

  # SERVER
  def init(:no_args) do
    Process.send_after(self(), :kickoff, 0)
    {:ok, {}}
  end

  def handle_info(:kickoff, {}) do
    numNodes = 20
    numMiners = 5
    :ets.new(:MitbitsCryptocurrencyWeb, [:set, :public, :named_table])

    {numNodes, numMiners}
    |> spawn_miners()
    |> create_genesis_block()
    |> spawn_miner_nodes()
    |> spawn_nodes()
    |> start_mining()
    |> start_stats()
    |> make_transactions()

    #  assert 1+1 == 1

    {:noreply, {}}
  end

  def start_stats({acc, node_hash, miner_node_hash, miner_pk_hash_sk, numNodes, numMiners}) do
    # IO.inspect System.system_time(:seconds)
    :ets.insert(:MitbitsCryptocurrencyWeb, {"time_blockchain", [{System.system_time(:seconds), []}]})
    MitbitsCryptocurrencyWeb.Stats.start()
    # IO.puts "hey"
    {acc, node_hash, miner_node_hash, miner_pk_hash_sk, numNodes, numMiners}
  end

  def spawn_miners({numNodes, numMiners}) do
    miner_pk_hash_sk =
      Enum.map(1..numMiners, fn _ ->
        {:ok, {sk, pk}} = RsaEx.generate_keypair()
        hash_name = MitbitsCryptocurrencyWeb.Utility.getHash(pk)
        {:ok, _} = MitbitsCryptocurrencyWeb.MinerSupervisor.add_miner(pk, sk, hash_name)
        {pk, hash_name, sk}
      end)

    miners =
      Enum.map(miner_pk_hash_sk, fn {_, hash_name, _} ->
        {hash_name}
      end)

    :ets.insert(:MitbitsCryptocurrencyWeb, {"miners", miners})
    {miner_pk_hash_sk, numNodes, numMiners}
  end

  def create_genesis_block({miner_pk_hash_sk, numNodes, numMiners}) do
    [{_, first_miner_hash, _} | _] = miner_pk_hash_sk

    {genesis_block} =
      GenServer.call(
        MitbitsCryptocurrencyWeb.Utility.string_to_atom("miner_" <> first_miner_hash),
        {:mine_first, "thefoxjkfsndaljd"}
      )

    :ets.insert(:MitbitsCryptocurrencyWeb, {"prev_block_hash", genesis_block.hash})
    {genesis_block, miner_pk_hash_sk, numNodes, numMiners}
  end

  def spawn_miner_nodes({genesis_block, miner_pk_hash_sk, numNodes, numMiners}) do
    miner_node_hash =
      Enum.map(miner_pk_hash_sk, fn {pk, hash_name, sk} ->
        {:ok, _} = MitbitsCryptocurrencyWeb.NodeSupervisor.add_node(pk, sk, genesis_block, hash_name)

        {:ok} =
          GenServer.call(MitbitsCryptocurrencyWeb.Utility.string_to_atom("node_" <> hash_name), :update_wallet)

        {:ok} =
          GenServer.call(
            MitbitsCryptocurrencyWeb.Utility.string_to_atom("node_" <> hash_name),
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
        hash_name = MitbitsCryptocurrencyWeb.Utility.getHash(pk)

        if(hash_name != miner_node_hash) do
          {:ok, _} = MitbitsCryptocurrencyWeb.NodeSupervisor.add_node(pk, sk, genesis_block, hash_name)

          {:ok} =
            GenServer.call(
              MitbitsCryptocurrencyWeb.Utility.string_to_atom("node_" <> hash_name),
              :add_latest_block_to_indexded_blockchain
            )
        end

        {hash_name}
      end)

    all_nodes = miner_node_hash ++ node_hash

    # IO.inspect(node_hash)
    :ets.insert(:MitbitsCryptocurrencyWeb, {"nodes", all_nodes})

    Enum.each(node_hash, fn {hash} ->
      GenServer.cast(
        MitbitsCryptocurrencyWeb.Utility.string_to_atom("node_" <> first_miner_hash),
        {:req_for_MitbitsCryptocurrencyWeb, 10, hash}
      )
    end)

    {node_hash, miner_node_hash, miner_pk_hash_sk, numNodes, numMiners}
  end

  def start_mining({node_hash, miner_node_hash, miner_pk_hash_sk, numNodes, numMiners}) do
    acc =
      Enum.reduce(miner_pk_hash_sk, 0, fn {_, miner_hash, _}, acc ->
        MitbitsCryptocurrencyWeb.Miner.start_mining(miner_hash)
        acc + 1
      end)

    {acc, node_hash, miner_node_hash, miner_pk_hash_sk, numNodes, numMiners}
  end

  def make_transactions({acc, node_hash, miner_node_hash, miner_pk_hash_sk, numNodes, numMiners}) do
    [{_, all_nodes}] = :ets.lookup(:MitbitsCryptocurrencyWeb, "nodes")

    Enum.each(1..(acc * 2000), fn i ->
      {node1_hash} = Enum.random(all_nodes)
      {node2_hash} = Enum.random(all_nodes)
      amount = Enum.random(1..10)

      GenServer.cast(
        MitbitsCryptocurrencyWeb.Utility.string_to_atom("node_" <> node1_hash),
        {:req_for_MitbitsCryptocurrencyWeb, amount, node2_hash}
      )
    end)
  end
end
