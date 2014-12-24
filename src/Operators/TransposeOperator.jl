

export TransposeOperator




type TransposeOperator{T<:Number,B<:BandedOperator} <: BandedOperator{T} 
    op::B
end

TransposeOperator{T<:Number}(B::BandedOperator{T})=TransposeOperator{T,typeof(B)}(B)


domainspace(P::TransposeOperator)=rangespace(P.op)
rangespace(P::TransposeOperator)=domainspace(P.op)

domain(P::TransposeOperator)=domain(P.op)

bandinds(P::TransposeOperator)=-bandinds(P.op)[end],-bandinds(P.op)[1]


function addentries!{T<:Number}(P::TransposeOperator,A,kr::Range1)
    error("Fix sazeros")
    br=bandinds(P.op)
    kr2=max(kr[1]-br[end],1):kr[end]-br[1]
    B=sazeros(T,kr2,Range1(br...))
    addentries!(P.op,B,kr2)

    brP=bandrange(P)
    for k=kr,j=brP
        if k+j>=1
            A[k,j] = B[k+j,-j]
        end
    end
    A
end


transpose(A::BandedOperator)=TransposeOperator(A)
ctranspose{T<:Real}(A::BandedOperator{T})=TransposeOperator(A)



