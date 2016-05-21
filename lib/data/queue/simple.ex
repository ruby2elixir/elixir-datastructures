#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Data.Queue.Simple do
  @moduledoc """
  A simple and performant queue.
  """

  defstruct enqueue: [], dequeue: []

  @opaque t :: __MODULE__.t
  @type   v :: any

  @doc """
  Creates an empty queue.
  """
  @spec new :: t
  def new do
    %__MODULE__{}
  end

  @doc """
  Creates a new queue from the given enumerable.

  ## Examples

      iex> Data.Queue.Simple.new(1 .. 4)
      #Queue<[1,2,3,4]>

  """
  @spec new(Enum.t) :: t
  def new(enum) do
    %__MODULE__{dequeue: Data.to_list(enum)}
  end

  @doc """
  Enqueue a value in the queue.

  ## Examples

      iex> Data.Queue.Simple.new |> Data.Queue.enq(42) |> Data.Queue.enq(23) |> Data.Queue.enq(1337)
      #Queue<[42,23,1337]>

  """
  @spec enq(t, v) :: t
  def enq(%__MODULE__{enqueue: [], dequeue: []}, value) do
    %__MODULE__{dequeue: [value]}
  end

  # minor amortization in case of two enqs
  def enq(%__MODULE__{enqueue: enq, dequeue: [deq]}, value) do
    %__MODULE__{enqueue: enq, dequeue: [deq, value]}
  end

  def enq(%__MODULE__{enqueue: enq, dequeue: deq}, value) do
    %__MODULE__{enqueue: [value | enq], dequeue: deq}
  end

  @doc """
  Dequeue a value from the queue.

  ## Examples

      iex> Data.Queue.Simple.new |> Data.Queue.enq(42) |> Data.Queue.enq(23) |> Data.Queue.deq
      {42,#Queue<[23]>}
      iex> Data.Queue.Simple.new |> Data.Queue.deq(:empty)
      {:empty,#Queue<[]>}

  """
  @spec deq(t)    :: { v, t }
  @spec deq(t, v) :: { v, t }
  def deq(queue, default \\ nil)

  def deq(%__MODULE__{enqueue: [], dequeue: []}, default) do
    { default, %__MODULE__{} }
  end

  def deq(%__MODULE__{enqueue: [], dequeue: [deq]}, _) do
    { deq, %__MODULE__{} }
  end

  def deq(%__MODULE__{enqueue: [enq], dequeue: [deq]}, _) do
    { deq, %__MODULE__{dequeue: [enq]} }
  end

  def deq(%__MODULE__{enqueue: enq, dequeue: [value]}, _) do
    { value, %__MODULE__{dequeue: Enum.reverse(enq)} }
  end

  def deq(%__MODULE__{enqueue: enq, dequeue: [head | rest]}, _) do
    { head, %__MODULE__{enqueue: enq, dequeue: rest} }
  end

  @doc """
  Dequeue a value from the queue, raising if it's empty.

  ## Examples

      iex> Data.Queue.Simple.new |> Data.Queue.enq(42) |> Data.Queue.deq!
      {42,#Queue<[]>}
      iex> Data.Queue.Simple.new |> Data.Queue.deq!
      ** (Data.Empty) the queue is empty

  """
  @spec deq!(t) :: { v, t } | no_return
  def deq!(%__MODULE__{enqueue: [], dequeue: []}) do
    raise Data.Empty
  end

  def deq!(queue) do
    deq(queue)
  end

  @doc """
  Peek the element that would be dequeued.

  ## Examples

      iex> Data.Queue.Simple.new |> Data.Queue.enq(42) |> Data.Queue.peek
      42
      iex> Data.Queue.Simple.new |> Data.Queue.peek(:empty)
      :empty

  """
  @spec peek(t)    :: v
  @spec peek(t, v) :: v
  def peek(queue, default \\ nil)

  def peek(%__MODULE__{enqueue: [], dequeue: []}, default) do
    default
  end

  def peek(%__MODULE__{dequeue: [value | _]}, _) do
    value
  end

  @doc """
  Peek the element that should be dequeued, raising if it's empty.

  ## Examples

      iex> Data.Queue.Simple.new |> Data.Queue.enq(42) |> Data.Queue.enq(23) |> Data.Queue.peek!
      42
      iex> Data.Queue.Simple.new |> Data.Queue.peek!
      ** (Data.Empty) the queue is empty

  """
  @spec peek!(t) :: v | no_return
  def peek!(%__MODULE__{enqueue: [], dequeue: []}) do
    raise Data.Empty
  end

  def peek!(queue) do
    peek(queue)
  end

  @doc """
  Reverse the queue.

  ## Examples

      iex> Data.Queue.Simple.new(1 .. 4) |> Data.Queue.reverse
      #Queue<[4,3,2,1]>

  """
  @spec reverse(t) :: t
  def reverse(%__MODULE__{enqueue: enq, dequeue: deq}) do
    %__MODULE__{enqueue: deq, dequeue: enq}
  end

  @doc """
  Check if the queue is empty.
  """
  @spec empty?(t) :: boolean
  def empty?(%__MODULE__{enqueue: [], dequeue: []}) do
    true
  end

  def empty?(%__MODULE__{}) do
    false
  end

  @spec clear(t) :: t
  def clear(_) do
    %__MODULE__{}
  end

  @doc """
  Check if the the value is present in the queue.
  """
  @spec member?(t, v) :: boolean
  def member?(%__MODULE__{enqueue: [], dequeue: []}) do
    false
  end

  def member?(%__MODULE__{enqueue: enq, dequeue: deq}, value) do
    Enum.member?(enq, value) or Enum.member?(deq, value)
  end

  @doc """
  Get the size of the queue.
  """
  @spec size(t) :: non_neg_integer
  def size(%__MODULE__{enqueue: enq, dequeue: deq}) do
    length(enq) + length(deq)
  end

  @doc """
  Fold the queue from the left.
  """
  @spec foldl(t, any, ((v, any) -> any)) :: any
  def foldl(%__MODULE__{enqueue: enq, dequeue: deq}, acc, fun) do
    List.foldr(enq, List.foldl(deq, acc, fun), fun)
  end

  @doc """
  Fold the queue from the right.
  """
  @spec foldr(t, any, ((v, any) -> any)) :: any
  def foldr(%__MODULE__{enqueue: enq, dequeue: deq}, acc, fun) do
    List.foldr(deq, List.foldl(enq, acc, fun), fun)
  end

  @doc """
  Convert the queue to a list.
  """
  @spec to_list(t) :: [v]
  def to_list(%__MODULE__{enqueue: enq, dequeue: deq}) do
    deq ++ Enum.reverse(enq)
  end
end

defimpl Data.Queue, for: Data.Queue.Simple do
  defdelegate enq(self, value), to: Data.Queue.Simple
  defdelegate deq(self), to: Data.Queue.Simple
  defdelegate deq(self, default), to: Data.Queue.Simple
  defdelegate deq!(self), to: Data.Queue.Simple
end

defimpl Data.Peekable, for: Data.Queue.Simple do
  defdelegate peek(self), to: Data.Queue.Simple
  defdelegate peek(self, default), to: Data.Queue.Simple
  defdelegate peek!(self), to: Data.Queue.Simple
end

defimpl Data.Sequence, for: Data.Queue.Simple do
  def first(self) do
    Data.Queue.Simple.peek(self)
  end

  def next(self) do
    if Data.Queue.Simple.size(self) > 1 do
      { _, next } = Data.Queue.Simple.deq(self)

      next
    end
  end
end

defimpl Data.Reversible, for: Data.Queue.Simple do
  defdelegate reverse(self), to: Data.Queue.Simple
end

defimpl Data.Emptyable, for: Data.Queue.Simple do
  defdelegate empty?(self), to: Data.Queue.Simple
  defdelegate clear(self), to: Data.Queue.Simple
end

defimpl Data.Reducible, for: Data.Queue.Simple do
  defdelegate reduce(self, acc, fun), to: Data.Queue.Simple, as: :foldl
end

defimpl Data.Listable, for: Data.Queue.Simple do
  defdelegate to_list(self), to: Data.Queue.Simple
end

defimpl Data.Contains, for: Data.Queue.Simple do
  defdelegate contains?(self, value), to: Data.Queue.Simple, as: :member?
end

defimpl Enumerable, for: Data.Queue.Simple do
  use Data.Enumerable
end

defimpl Inspect, for: Data.Queue.Simple do
  import Inspect.Algebra

  def inspect(queue, opts) do
    concat ["#Queue<", Kernel.inspect(Data.Queue.Simple.to_list(queue), opts), ">"]
  end
end
