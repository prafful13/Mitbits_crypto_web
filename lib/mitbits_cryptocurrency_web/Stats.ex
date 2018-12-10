defmodule MitbitsCryptocurrencyWeb.Stats do
  use GenServer
  @me __MODULE__
  # API
  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args, name: @me)
  end

  def start() do
    GenServer.cast(@me, :start)
  end

  # SERVER
  def init(:no_args) do
    {:ok, {}}
  end

  def handle_cast(:start, {}) do
    [{_, all_nodes}] = :ets.lookup(:MitbitsCryptocurrencyWeb, "nodes")
    # IO.puts "hey"
    numNodes = Enum.count(all_nodes)
    # IO.inspect numNodes



    if(numNodes == 25) do
      [{_,curr_list}] = :ets.lookup(:MitbitsCryptocurrencyWeb, "time_blockchain")
      #[{_,base_time}] = :ets.lookup(:MitbitsCryptocurrencyWeb, "base_time")
      [latest_entry | _ ] = curr_list
      {prev_time, prev_blockchain} = latest_entry
      curr_time = System.system_time(:seconds)
      diff = curr_time - prev_time
      # IO.inspect diff
      if(diff >= 1) do
        [{first_node_hash} | _ ] = all_nodes
        {latest_blockchain} = GenServer.call(MitbitsCryptocurrencyWeb.Utility.string_to_atom("node_"<>first_node_hash), :get_blockchain)
        new_entry = {curr_time, latest_blockchain}
        updated_list = [new_entry | curr_list]
        :ets.insert(:MitbitsCryptocurrencyWeb, {"time_blockchain", updated_list})
        Enum.each(updated_list, fn {timestamp, blockchain} ->
#          IO.inspect([timestamp, Enum.count(blockchain)])
        end)
#        total_bitcoins = Enum.reduce(blockchain, 0, fn block, total ->
#          txns = block.txns
#
#          reward = Enum.reduce(txns, 0, fn txn, amt ->
#              if(txn.message.amount > 70) do
#                txn.message.amount
#              end
#          end)
#          reward + total
#        end)
#
#        :ets.insert(:MitbitsCryptocurrencyWeb, {"total_bitcoins", total_bitcoins})
      end
    end


    start()
    {:noreply, {}}
  end
end
