# genetic algorithm problem from
# http://www.ai-junkie.com/ga/intro/gat3.html

defmodule GAHelper do
  @doc ~S"""
  Given a function that creates a member of a population and the size
  of the population, this function creates a list containing size
  members of a population
  """
  def gen_population(gen_sol_fn, size) do
    Stream.repeatedly(gen_sol_fn) |> Enum.take(size)
  end

  def select_breeding_population(population, fitness_fn, aim, size) do
    Enum.sort(population, fn a, b -> fitness_fn.(a, aim) <= fitness_fn.(b, aim) end)
    |> Enum.slice(0..size)
  end

  def breed_new_pop(selected, size, breed_fn, new_pop \\ []) do
    if length(new_pop) == size do
      new_pop
    else
      idx1 = :rand.uniform(length(selected)-1)-1
      idx2 = :rand.uniform(length(selected)-1)-1
      pop = [breed_fn.(Enum.at(selected, idx1) , Enum.at(selected, idx2)) | new_pop]
      breed_new_pop(selected, size, breed_fn, pop)
    end
  end
end

defmodule NumberGA do
  defmodule Interleave do
    @doc ~S"""
    Takes two lists, a and b and returns them in the form
    [a[0], b[0], a[1], b[1]...]
    https://gist.github.com/sunaku/445900678be17fc5f2fe
    """
    def interleave(a,     b,  result \\ [])
    def interleave([],    [], result), do: result |> Enum.reverse
    def interleave([],    b,  result), do: interleave(b, [], result)
    def interleave([h|t], b,  result), do: interleave(b, t, [h | result])
  end

  def find_solution(aim, pop \\ [], gen \\ 0) do
    if pop == [] do
      pop = GAHelper.gen_population(&gen_solution/0, 20)
    end
    new_gen = gen + 1
    breeding = GAHelper.select_breeding_population(pop, &fitness/2, aim, 10)
    new_pop = GAHelper.breed_new_pop(breeding, 20, &breed/2)
    fit = Enum.map(new_pop, fn x -> fitness(x, aim) end)
    if Enum.reduce(fit, fn x, acc -> min(x, acc) end) != 0 do
      IO.puts("Gen #{new_gen}")
      IO.inspect(fit)
      IO.inspect(average(fit))
      find_solution(aim, new_pop, new_gen)
    else
      display_solution Enum.find(new_pop, fn x -> fitness(x, aim) == 0 end)
    end
  end

  def average(sols) do
    total = Enum.reduce(sols, fn x, acc -> x + acc end)
    total / length(sols)
  end

  def display_solution solution do
    IO.write("((((")
    for idx <- 0..(length(solution)-1) do
      if rem(idx, 2) == 0 do
        IO.write("#{Enum.at(solution, idx)})")
      else
        case Enum.at(solution, idx) do
          0 -> IO.write(" + ")
          1 -> IO.write(" - ")
          2 -> IO.write(" * ")
          3 -> IO.write(" / ")
        end
      end
    end
  end

  @doc ~S"""
  Creates a 'gene sequence' that corresponds to a potential solution to
  the problem at hand

  The gene sequence should comprise 6 genes that correspond to either
  the numerals 0-9 or the 4 basic arithmetic operators. Even elements
  should be digits and odd elements operators
  """
  def gen_solution do
    digits = Enum.map(List.duplicate("_", 4), fn _ -> :rand.uniform(10) - 1 end)
    operators = Enum.map(List.duplicate("_", 3), fn _ -> :rand.uniform(4) - 1 end)

    Interleave.interleave(digits, operators)
  end

  def fitness(solution, aim) do
    eval_solution(solution) - aim
    |> abs
  end

  def breed(sol1, sol2) do
    Enum.slice(sol1, 0, 4) ++ Enum.slice(sol2, 4, 3)
    |> mutate
  end

  def mutate(sol, new_sol \\ []) do
    mutate_rate = 0.2
    lns = length new_sol
    if length(sol) != lns do
      muted = mutate_bit(Enum.at(sol, lns), lns, mutate_rate)
      mutate(sol, [muted | new_sol])
    else
      Enum.reverse(new_sol)
    end
  end

  defp mutate_bit(bit, idx, mut_rate) do
    if :rand.uniform() < mut_rate do
      case rem(idx, 2) do
        0 -> rem(:rand.uniform(9) + bit, 10)
        1 -> rem(:rand.uniform(3) + bit, 4)
      end
    else
      bit
    end
  end

  def eval_solution([result]) do
    result
  end
  def eval_solution(solution) do
    [dig1, op, dig2 | tail] = solution
    case op do
      0 -> res = dig1 + dig2
      1 -> res = dig1 - dig2
      2 -> res = dig1 * dig2
      3 ->
        if dig2 != 0 do
          res = dig1 / dig2
        else
          res = 0
        end
    end
    eval_solution [res] ++ tail
  end
end

aim = 137

NumberGA.find_solution(aim)
