defmodule MitbitsCryptocurrencyWebWeb.HelloController do
  use MitbitsCryptocurrencyWebWeb, :controller

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
    render(conn, "account.html", balance: balance, participant: participant, nodes: other_nodes)
  end

  def create(conn, params) do
    participant = Map.get(params, "participant")
    to = Map.get(params, "to")
    amount = String.to_integer(Map.get(params, "amount"))

    {txn} = GenServer.call(
      MitbitsCryptocurrencyWeb.Utility.string_to_atom("node_" <> participant),
      {:req_for_MitbitsCryptocurrencyWeb, amount, to}
    )

    if(txn != :invalid) do
      id = txn.id
      render(conn, "txn.html", participant: participant, to: to, amount: amount, signature: id)
    else
      signature = :invalid
      render(conn, "txn.html", participant: participant, to: to, amount: amount, signature: signature)
    end
  end

  def blockchain(conn, params) do
    [{_, node_hash}] = :ets.lookup(:MitbitsCryptocurrencyWeb, "nodes")

    {first} = Enum.at(node_hash, 0)

    {blockchain} =
      GenServer.call(
        MitbitsCryptocurrencyWeb.Utility.string_to_atom("node_" <> first),
        :get_blockchain
      )

#      blockchain = Enum.reduce(blockchain, [], fn block, list ->
#        txns_list = Enum.reduce(block.txns, [], fn txn, txn_list ->
#          # IO.inspect txn
#          txn_list ++ [Map.to_list(txn)]
#        end)
#        IO.inspect block
#        {_,block} = Map.get_and_update(block, :txns, fn curr -> {curr, txns_list} end)
#        # block.txns = txns_list
#        list ++ [Map.to_list(block)]
#      end)
#
      #IO.inspect blockchain

    render(conn, "blockchain.html", blockchain: blockchain)
  end

  def stats(conn, params) do
    [{_, data}] = :ets.lookup(:MitbitsCryptocurrencyWeb, "time_blockchain")

    [{_, node_hash}] = :ets.lookup(:MitbitsCryptocurrencyWeb, "nodes")

    [{_, miners_hash}] = :ets.lookup(:MitbitsCryptocurrencyWeb, "miners")

    {first} = Enum.at(node_hash, 0)

    indexed_blockchain =
      GenServer.call(
        MitbitsCryptocurrencyWeb.Utility.string_to_atom("node_" <> first),
        :get_indexed_blockchain
      )

    list =
      Enum.reduce(miners_hash, [], fn {hash}, list ->
        list ++ [MitbitsCryptocurrencyWeb.Utility.string_to_atom("node_" <> hash)]
      end)

    {miners, nodes} = Map.split(indexed_blockchain, list)

    [{first_miner} | _ ] = miners_hash

    {curr_blockchain} = GenServer.call(MitbitsCryptocurrencyWeb.Utility.string_to_atom("node_"<>first_miner), :get_blockchain)
    remaining_txns = GenServer.call(MitbitsCryptocurrencyWeb.Utility.string_to_atom("node_"<>first_miner), :get_txn_list)

    {count_mined_txns, total_bitcoins} = Enum.reduce(curr_blockchain, {0, 900}, fn block, {count, tot} ->
      {count + Enum.count(block.txns), tot + 100}
    end)
    count_remaining_txns = Enum.count(remaining_txns)

    render(conn, "stat.html", data: data, miners: miners, nodes: nodes, count_remaining_txns: count_remaining_txns, count_mined_txns: count_mined_txns, total_bitcoins: total_bitcoins)
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

    render(conn, "random.html")
  end
end
