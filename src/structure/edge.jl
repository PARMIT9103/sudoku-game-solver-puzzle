include("node.jl")

using Combinatorics: combinations

using Lazy: @>>, any, map, filter

struct Edge
    nodes::Tuple{SudokuNode,SudokuNode}

    function Edge(nodes::Vector{SudokuNode})
        return new(tuple(nodes...))
    end
end

function get_nodes(edge::Edge)::Vector{SudokuNode}
    return collect(edge.nodes)
end

function get_nodes(edges::Vector{Edge})::Vector{SudokuNode}
    return get_nodes.(edges)
end

function are_adjacent(edge::Edge)::Bool
    a, b = get_full_coordinates.(edge.nodes)
    return any(a .== b)
end

function Base.in(node::SudokuNode, edge::Edge)::Bool
    return any(isequal.(fill(node), edge.nodes))
end

function nodes_to_edges(nodes::Vector{SudokuNode})::Vector{Edge}
    return @>> begin
        combinations(nodes, 2)
        map(Edge)
        filter(are_adjacent)
    end
end
