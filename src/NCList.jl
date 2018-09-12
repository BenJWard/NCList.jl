struct NCListInterval
    start::Int64
    stop::Int64
    id::Int64
    sublist::Int64
end

function Base.isless(x::NCListInterval, y::NCListInterval)
    return x.start < y.start || (x.start == y.start && x.stop > y.stop)
end

function Base.isequal(x::NCListInterval, y::NClistInterval)
    return x.start == y.start && x.stop == y.stop
end

@inline function inbounds_update_interval_sublist!(L, i, sublist)
    @inbounds L[i] = NCListInterval(L[i].start, L[i].stop, L[i].id, sublist)
end

struct SublistHeader
    start::Int64
    len::Int64
end

SublistHeader() = SublistHeader(0, 0)

@inline function inbounds_update_header_start!(H, i, start)
    @inbounds H[i] = SublistHeader(start, H[i].len)
end
@inline function inbounds_increment_header_len!(H, i)
    @inbounds H[i] = SublistHeader(H[i].start, H[i].len + 1)
end
@inline function inbounds_update_header_len!(H, i, len)
    @inbounds H[i] = SublistHeader(H[i].start, len)
end

struct NCList
    L::Vector{NCListInterval}
    H::Vector{SublistHeader}
    n::Int64
    ntop::Int64
    nlists::Int64
end

function build_nested_list!(L, n)
    sort!(L)
    nlists = 1
    for i in 2:n
        # i is not contained in parent or are the same interval.
        if L[i].stop > H[i - 1].stop || isequal(L[i], [i - 1])
            nlists += 1
        end
    end
    
    if nlists == 1
        return (n, 0, Vector{SublistHeader}(undef, 0))
    end
    
    H = Vector{SublistHeader}(SublistHeader(), nlists + 1)
    fill!(H, SublistHeader)
    
    L[1].sublist = 1
    H[1] = SublistHeader(-1, 1)
    nlists = 1
    isublist = 2
    i = 2
    parent = 1
    
    while i <= n
        # i is not contained in parent or are the same interval.
        if Bool(isublist) && (L[i].stop > H[parent].stop || isequal(L[i], L[parent])
            # H[isublist].start = H[L[parent].sublist].len - 1
            inbounds_update_header_start!(H, isublist, H[L[parent].sublist].len - 1) # record parent relative position
            isublist = L[parent].sublist
            parent = H[L[parent].sublist].start
        else
            if H[isublist].len == 0
                nlists += 1
            end
            # H[isublist].len++
            inbounds_increment_header_len!(H, isublist)
            inbounds_update_interval_sublist!(L, i, isublist)
            parent = i
            isublist = nlists
            # H[isublist].start = parent
            inbounds_update_header_start!(H, isublist, parent)
            i += 1
        end
    end
    
    while isublist > 0 # pop the remaining stack
        # H[isublist].start = H[L[parent].sublist].len - 1
        # record parent relative position.
        inbounds_update_header_start!(H, isublist, H[L[parent].sublist].len - 1)
        isublist = L[parent].sublist
        parent = H[L[parent].sublist].start
    end
    
    pn = H[1].len
    total = 0
    for i in 1:nlists+1
        temp = H[i].len
        #H[i].len = total
        inbounds_update_header_len!(H, i, total)
        total += temp
    end
    # Subheader.len should now be the start of the sublist.
    
    for i in 2:n
        if L[i].sublist > L[i - 1].sublist
            H[L[i].sublist].start += H[L[i - 1].sublist].len
        end
    end
    # Subheader.start should not be the absolute position of the parent.
    
    sort!(L, )
    
    # At this point the sublists are grouped together for packing.
    
end

function NCList(starts::Vector{Int64}, ends::Vector{Int64}, ids)
    len = length(starts)
    n = length(starts)
    L = Vector{NCListInterval}(undef, n)
    for i in 1:len
        L[i] = NCListInterval(starts[i], ends[i], ids[i], -1)
    end
    
end
