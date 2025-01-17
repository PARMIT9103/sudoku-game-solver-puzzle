using Lazy: any, all

mutable struct SudokuNode
    """A node for constructing sudoku graphs

    Holds a value, its own coordinates, which cell of the board it's in,
    and what potential values it can have (desaturated values).
    """
    coordinates::Tuple{Int,Int}
    cell::Int
    value::Int

    possible_values::Vector{Int}


    function SudokuNode(coordinates::Tuple{Int,Int})
        return new(coordinates, 0, 0, [])
    end
end

function get_possible_values(node::SudokuNode)::Vector{Int}
    return node.possible_values
end

function get_value(node::SudokuNode)::Int
    return node.value
end

function set_value!(node::SudokuNode, value::Int)::SudokuNode
    node.value = value
    return node
end

function set_cell!(node::SudokuNode, psize::Int)::SudokuNode
    """Given a node and the psize (N) of the sudoku it's in,
    set the node's cell value. The cell is which of the squares
    the nodes fall into, numbered 1-N^2 from the top left to bottom right."""
    row, col = node.coordinates .- 1
    node.cell = 1 + floor(((col // psize) + row) - (row % psize))
    return node
end

function get_full_coordinates(node::SudokuNode)::Tuple{Int,Int,Int}
    "Get the 'full' coordinates for a node, in the form (Row, Column, Cell)"
    return (node.coordinates..., node.cell)
end

function Base.isequal(a::SudokuNode, b::SudokuNode)::Bool
    a, b = get_full_coordinates.((a, b))
    return all(a .== b)
end

function are_adjacent(a::SudokuNode, b::SudokuNode)::Bool
    a, b = get_full_coordinates.((a, b))
    return any(a .== b)
end

function remove_possibility!(node::SudokuNode, value::Int)::SudokuNode
    node.possible_values = [val for val in node.possible_values if val != value]
    return node
end
