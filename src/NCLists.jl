
module NCLists

include("ncinterval.jl")
include("sublistheader.jl")

struct NCList
    L::Vector{NCInterval}
    H::Vector{SublistHeader}
    n::Int64
    ntop::Int64
    nlists::Int64
end


@inline function inbounds_update_interval_sublist!(L, i, sublist)
    @inbounds L[i] = NCInterval(L[i].start, L[i].stop, L[i].id, sublist)
end

@inline function inbounds_update_header_start!(H, i, start)
    @inbounds H[i] = SublistHeader(start, H[i].len)
end

@inline function inbounds_increment_header_len!(H, i)
    @inbounds H[i] = SublistHeader(H[i].start, H[i].len + 1)
end

@inline function inbounds_update_header_len!(H, i, len)
    @inbounds H[i] = SublistHeader(H[i].start, len)
end



## Construction


function count_nlists(L::Vector{NCInterval})
    nlists = 1
    @inbounds for i in 2:n
        nlists += ifelse(!(is_not_contained_or_same(L[i], L[i - 1])), 1, 0)
    end
    return nlists
end

function build_nested_list_inplace!(L, n) # ntop, nlists, H
    
    # First we sort the intervals, by their start position,
    # (longer intervals first).
    sort!(L, lt = start_isless)
    
    # Scan sorted intervals and count how many lists (including sublists) there are.
    nlists = count_nlists(L)
    
    # If nlists is 1, there are no intervals contained within other intervals,
    # so there are no sublists of intervals, only one top level list.
    # We return an empty H vector.
    if nlists == 1
        return (n, 0, Vector{SublistHeader}(undef, 0))
    end
    
    # Create a H vector with memory pre-allocated with space for all the sublist
    # headers. Fill it with null SublistHeader 
    H = Vector{SublistHeader}(undef, nlists + 1)
    
    # L[1].sublist = 1
    # Set the sublist of the first interval and initialize the first 
    # SublistHeader.
    inbounds_update_interval_sublist(L, 1, 1)
    H[1] = SublistHeader(-1, 1)
    nlists = 1
    isublist = 2
    parent = 1
    
    i = 2
    while i <= n
        # IF isublist is not 0 and i is not contained in i - 1 or they are the same.
        if Bool(isublist) && is_not_contained_or_same(L[i], L[parent])
            parent_sublist = L[parent].sublist
            parent_sublist_header = H[parent_sublist]
            # Set the start of isublist's header to the length of the parent sublist's header - 1.
            inbounds_update_header_start!(H, isublist, parent_sublist_header.len - 1)
            isublist = parent_sublist
            parent = parent_sublist_header.start
        else # Interval is contained and not the same... 
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
        # H[i].len = total
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
    
    sort!(L, lt = sublist_isless)
    
    # At this point the sublists are grouped together for packing.
    
    isublist = 1
    H[1] = SublistHeader(0, 0)
    for i in 1:n
        if L[i].sublist > isublist
            isublist = L[i].sublist
            parent = H[isublist].start
            # L[parent].sublist = isublist - 1
            inbounds_update_interval_sublist!(L, parent, isublist - 1)
            H[isublist] = SublistHeader(i, 0)
        end
        # H[isublist].len += 1
        inbounds_increment_header_len!(H, isublist)
        # L[i].sublist = -1
        inbounds_update_interval_sublist!(L, i, -1)
    end
    
    nlists -= 1
    
    return (n, nlists, H)
        
end

function NCList(starts::Vector{Int64}, ends::Vector{Int64}, ids)
    len = length(starts)
    n = length(starts)
    L = Vector{NCListInterval}(undef, n)
    for i in 1:len
        L[i] = NCListInterval(starts[i], ends[i], ids[i], -1)
    end
    
end

end # NCList module.
