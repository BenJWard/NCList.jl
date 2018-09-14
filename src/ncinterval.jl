struct NCInterval
    start::Int64
    stop::Int64
    id::Int64
    sublist::Int64
end

function Base.show(io::IO, x::NCInterval)
    println(io, "Interval: [ Start: ", x.start, ", Stop: ", x.stop, ", ID: ", x.id, ", Sublist: ", x.sublist)
end

function Base.isequal(x::NCInterval, y::NCInterval)
    return x.start == y.start && x.stop == y.stop
end

# sort intervals by start position, if start is the same, then longer intervals come first.
function start_isless(x::NCInterval, y::NCInterval)
    return x.start < y.start || (x.start == y.start && x.stop > y.stop)
end

# sort intervals in sublist order, and secondarily by the start.
function sublist_isless(x::NCInterval, y::NCInterval)
    return x.sublist < y.sublist || x.start < y.start
end

# Tests if x IS NOT contained in or IS EQUAL to y.
is_not_contained_or_same(x::NCInterval, y::NCInterval) = x.stop > y.stop || isequal(x, y)