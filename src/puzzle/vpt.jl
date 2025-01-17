# Validity-Preserving Transformations

include("../structure/graph.jl")

using Random: shuffle

@enum Transformation Swap Mirror Rotate Relabel
@enum Swappable Row Column Band Stack
@enum Axis Vertical Horizontal

function random_transformation!(graph::SudokuGraph)::SudokuGraph
    transformation_type = rand(instances(Transformation))
    return transform!(graph, transformation_type)
end

"""
    transform!(graph::SudokuGraph, type::Transformation)::SudokuGraph

Given a graph and a Transformation, apply the transformation and return the graph.
"""
function transform!(graph::SudokuGraph, type::Transformation)::SudokuGraph
    if type == Rotate
        graph = rotate!(graph)
    elseif type == Relabel
        graph = relabel!(graph)
    elseif type == Mirror
        graph = mirror!(graph)
    else
        swap_type = rand(instances(Swappable))
        targets = collect(1:graph.psize)
        targets = shuffle(targets)[1:2]
        graph = swap!(graph, swap_type, targets)
    end
    return graph
end

"""
    mirror!(graph::SudokuGraph)::SudokuGraph

Mirror the puzzle along a random axis.
"""
function mirror!(graph::SudokuGraph)::SudokuGraph
    axis = rand(instances(Axis))

    s = graph.psize^2
    for i in 1:s
        for j in 1:s÷2

            if axis == Vertical
                nodes = get_node.(((i,j),(i,s+1-j)), fill(graph))
            elseif axis == Horizontal
                nodes = get_node.(((j,i),(s+1-j,i)), fill(graph))
            end

            x,y = get_value.(nodes)
            set_value!.(nodes, [y,x])
        end
    end

    return graph
end

"""
    mirror!(graph::SudokuGraph, axis::Axis)::SudokuGraph

Same as mirror!(graph::SudokuGraph)
"""
function mirror!(graph::SudokuGraph, axis::Axis)::SudokuGraph
    s = graph.psize^2
    for i in 1:s
        for j in 1:s÷2
            if axis == Vertical
                nodes = get_node.(((i,j),(i,s+1-j)), fill(graph))
            elseif axis == Horizontal
                nodes = get_node.(((j,i),(s+1-j,i)), fill(graph))
            end
            x,y = get_value.(nodes)
            set_value!.(nodes, [y,x])
        end
    end

    return graph
end

"""
    rotate!(graph::SudokuGraph)::SudokuGraph

Rotate the puzzle 90 degrees to the left.
"""
function rotate!(graph::SudokuGraph)
    for node in graph.nodes
        x, y = node.coordinates
        # Plus 1 to account for Julia being 1-indexed
        node.coordinates = y, (1 + graph.psize^2) - x
    end

    return graph
end

"""
    relabel!(graph::SudokuGraph)::SudokuGraph

Relabel the numbers in a puzzle with a random, 1:1 map.
"""
function relabel!(graph::SudokuGraph)::SudokuGraph
    "Randomly relabel the numbers in the graph"
    targets = shuffle(1:graph.psize^2)

    for node in graph.nodes
        if node.value != 0
            node.value = targets[node.value]
        end
    end

    return graph
end

"""
    swap!(graph::SudokuGraph, swap_type::Swappable, targets::Vector{Int})::SudokuGraph

"Swap two rows or columns within a band or stack, or two bands/stacks"
"""
function swap!(graph::SudokuGraph, swap_type::Swappable, targets::Vector{Int})::SudokuGraph
    s = graph.psize

    if swap_type in (Row, Column)
        # Pick stack or band to update
        target_group = rand(1:graph.psize)

        # Calculate coordinates to update
        targets .= targets .+ (graph.psize * (target_group - 1))

        if swap_type == Row
            coord = 1
        else
            coord = 2
        end

        x = collect(filter(x->x.coordinates[coord]==targets[1], graph.nodes))
        y = collect(filter(x->x.coordinates[coord]==targets[2], graph.nodes))

        for (n1, n2) in zip(x, y)
            n1.value, n2.value = n2.value, n1.value
        end
    else
        # Swap band or stack (all rows or columns within)
        # Calculate groups to update
        groups = [collect(1:graph.psize) .+ (graph.psize * (targets[i] - 1)) for i in 1:2]

        if swap_type == Band
            coord = 1
        else
            coord = 2
        end

        # Swap all rows/columns between bands/stacks
        for (xs, ys) in zip(groups...)
            for (x, y) in zip(xs, ys)
                n1s = collect(filter(n->n.coordinates[coord]==x, graph.nodes))
                n2s = collect(filter(n->n.coordinates[coord]==y, graph.nodes))

                for (n1, n2) in zip(n1s, n2s)
                    n1.value, n2.value = n2.value, n1.value
                end
            end
        end
    end

    return graph
end
