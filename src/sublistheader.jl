
struct SublistHeader
    start::Int64
    len::Int64
end

SublistHeader() = SublistHeader(0, 0)

function Base.show(io::IO, x::SublistHeader)
    println("Sublist Header: [ Start:", x.start, ", Length: ", x.len)
end