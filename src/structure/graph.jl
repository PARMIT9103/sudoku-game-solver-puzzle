include("node.jl")
include("edge.jl")

using Lazy: @>, @>>, @as
using Base.Iterators: product, flatten

mutable struct SudokuGraph
    nodes::Vector{SudokuNode}
    edges::Vector{Edge}

    psize::Int

    function SudokuGraph(psize::Int)
        #=
        The node coordinates are (row, column, cell),
        generated by creating the cartesian set of (row, col)
        and then assigning the cell based on a formula.
        =#
        coordinate_range = 1:psize^2
        coordinate_grid = Iterators.product(coordinate_range, coordinate_range)
        nodes = SudokuNode.(coordinate_grid)
        set_cell!.(nodes, psize)

        nodes = reshape(nodes, psize^4)
        edges = nodes_to_edges(nodes)

        return new(nodes, edges, psize)
    end
end

"""
    get_node(coordinates::Tuple{Int,Int}, graph::SudokuGraph)::SudokuNode

Given node coordinates and a graph, return the node at those coordinates.
"""
function get_node(coordinates::Tuple{Int,Int}, graph::SudokuGraph)::SudokuNode
    return @>> graph.nodes begin
        filter(node -> node.coordinates == coordinates)
        pop!
    end
end

"""
    get_cell(graph::SudokuGraph, i::Int)::Vector{SudokuNode}

Given a sudoku graph and a cell (block) number, return all nodes in that group.
"""
function get_cell(graph::SudokuGraph, i::Int)::Vector{SudokuNode}
    return @>> graph.nodes begin
        filter(node -> node.cell == i)
        collect
    end
end

"""
    get_neighbors(node::SudokuNode, graph::SudokuGraph)::Vector{SudokuNode}

Given a node in a graph, return all of the nodes that it shares an edge with.
"""
function get_neighbors(node::SudokuNode, graph::SudokuGraph)::Vector{SudokuNode}
    return @>> graph.edges begin
        filter(edge -> node in edge)
        map(get_nodes)
        flatten
        collect
        filter(x -> !isequal(node, x))
    end
end

"""
    get_saturated_values(node::SudokuNode, graph::SudokuGraph)::Vector{Int}

Find the unique values held by the neighbors of a given node.
"""
function get_saturated_values(node::SudokuNode, graph::SudokuGraph)::Vector{Int}
    return @>> begin
        get_neighbors(node, graph)
        map(get_value)
        filter(x -> x != 0)
        unique
    end
end

"""
    get_saturation(node::SudokuNode, graph::SudokuGraph)::Int

For a given node in a graph, calculate its saturation. In this context,
this refers to the number of unique values held by its neighbors.
"""
function get_saturation(node::SudokuNode, graph::SudokuGraph)::Int
    return length(get_saturated_values(node, graph))
end

"""
    get_possible_values(node::SudokuNode, graph::SudokuGraph)::Vector{Int}

Given a node and the graph it's in, calculate its possible values by
taking the difference between the range of possible values and its saturated
values.
"""
function get_possible_values(node::SudokuNode, graph::SudokuGraph)::Vector{Int}
    sv = get_saturated_values(node, graph)
    return collect(filter(x -> x ∉ sv, 1:graph.psize^2))
end

"""
    set_possible_values!(node::SudokuNode, graph::SudokuGraph)::SudokuNode

Given a node and the graph it's in, calculate and set its possible_values field.
"""
function set_possible_values!(node::SudokuNode, graph::SudokuGraph)::SudokuNode
    node.possible_values = get_possible_values(node, graph)
    return node
end

"""
    set_value!(node::SudokuNode, value::Int, graph::SudokuGraph)::SudokuNode

Set a given node to a given value and update its empty neighbors' possibilities.
"""
function set_value!(node::SudokuNode, value::Int, graph::SudokuGraph)::SudokuNode
    node.value = value
    neighbors = get_neighbors(node, graph)
    neighbors = filter(x->get_value(x)==0, neighbors)
    set_possible_values!.(neighbors, fill(graph))
    return node
end

"""
    unset_value!(node::SudokuNode, graph::SudokuGraph)::SudokuNode

Blank out a given node and regenerate the list of its possible values.
"""
function unset_value!(node::SudokuNode, graph::SudokuGraph)::SudokuNode
    node.value = 0
    set_possible_values!(node, graph)
    return node
end

"""
    get_blank_nodes(graph::SudokuGraph)::Vector{SudokuNode}

Given a graph, return a list of the nodes that have no value yet.
"""
function get_blank_nodes(graph::SudokuGraph)::Vector{SudokuNode}
    return @>> begin
        graph.nodes
        filter(x -> get_value(x) == 0)
        collect
    end
end

"""
    get_nonblank_nodes(graph::SudokuGraph)::Vector{SudokuNode}

Given a graph, return a list of the nodes that have values.
"""
function get_nonblank_nodes(graph::SudokuGraph)::Vector{SudokuNode}
    return @>> begin
        graph.nodes
        filter(x -> get_value(x) != 0)
        collect
    end
end

"""
    confirm_solution(graph::SudokuGraph)::Bool

Given a completed puzzle, confirm that it is correct.
"""
function confirm_solution(graph::SudokuGraph)::Bool
    # If the puzzle isn't done, it isn't solved :)
    if !(isempty(get_blank_nodes(graph)))
        return false
    end

    for edge in graph.edges
        nodes = get_nodes(edge)
        if get_value(nodes[1]) == get_value(nodes[2])
            return false
        end
    end
    return true
end