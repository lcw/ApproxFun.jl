##Line calculus


type MappedSpace{D<:Domain,S<:DomainSpace} <: IntervalDomainSpace
    domain::D
    space::S
    MappedSpace(d::D,sp::S)=new(d,sp)
    MappedSpace(d::D)=new(d,S())
    MappedSpace()=new(D(),S())
end

MappedSpace{D<:Domain,S<:DomainSpace}(d::D,s::S)=MappedSpace{D,S}(d,s)

typealias LineSpace MappedSpace{Line,ChebyshevSpace}
typealias RaySpace MappedSpace{Ray,ChebyshevSpace}


Space(d::Line)=LineSpace(d)
Space(d::Ray)=RaySpace(d)

domain(S::MappedSpace)=S.domain
canonicaldomain{D<:Domain,S}(::Type{MappedSpace{D,S}})=D()


## Construction

Base.ones{T<:Number}(::Type{T},S::MappedSpace)=Fun(ones(T,S.space).coefficients,S)
transform(S::MappedSpace,vals::Vector)=transform(S.space,vals)
itransform(S::MappedSpace,cfs::Vector)=itransform(S.space,cfs)
evaluate{S<:MappedSpace}(f::Fun{S},x)=evaluate(Fun(coefficients(f),space(f).space),tocanonical(f,x))

for op in (:(Base.first),:(Base.last))
    @eval $op{S<:MappedSpace}(f::Fun{S})=$op(Fun(coefficients(f),space(f).space))
end    



# Transform form chebyshev U series to dirichlet-neumann U series
function uneumann_dirichlet_transform{T<:Number}(v::Vector{T})
    n=length(v)
    w=Array(T,n-4)

    for k = n-4:-1:1
        sc=(3+k)*(4+k)/((-2-k)*(1+k))
        w[k]=sc*v[k+4] 
        
        if k <= n-6
            w[k]-=sc*2*(4+k)/(5+k)*w[k+2]
        end
        if k <= n-8
            w[k]+=sc*((6+k)/(4+k))*w[k+4]
        end
    end
    
    w
end


# This takes a vector in dirichlet-neumann series on [-1,1]
# and return coefficients in T series that satisfy
# (1-x^2)^2 u' = f
function uneumannrange_xsqd{T<:Number}(v::Vector{T})
    n = length(v)
    w=Array(T,n+1)
    
    for k=n:-1:1
        sc=-((16*(1+k)*(2+k))/(k*(3+k)*(4+k)))
        w[k+1]=sc*v[k]
        
        if k <= n-2
            w[k+1]-=sc*(k*(4+k))/(8(k+1))*w[k+3]
        end
        
        if k <= n-4
            w[k+1]+=sc*((k*(k+4))/(16(k+2)))*w[k+5]
        end
    end
    w[1]=zero(T)
    
    w
end




#integration functions
#integration is done by solving (1-x^2)^2 u' = (1-x^2)^2 M' f, u[-1] == 0



function integrate(f::Fun{LineSpace})
    d=domain(f)
    @assert d.α==d.β==-1.
    # || d.α==d.β==-.5
    
#    if domain(f).α==domain(f).β==-1.
        Fun(uneumannrange_xsqd(uneumann_dirichlet_transform(coefficients(Fun([1.5,0.,.5]).*Fun(f.coefficients),UltrasphericalSpace{1}))),f.space)
#    end
#     elseif d.α==d.β==-.5
#         u=divide_singularity(f)
#             integrate(SingFun(Fun(u),-.5,-.5))
#     end  

end

function integrate(f::Fun{RaySpace})
    x=Fun(identity)
    g=fromcanonicalD(f,x)*Fun(f.coefficients)
    Fun(integrate(Fun(g,ChebyshevSpace)).coefficients,space(f))
end

for T in (Float64,Complex{Float64})
    function Base.sum(f::Fun{LineSpace})
        d=domain(f)
        if d.α==d.β==-.5
            sum(Fun(divide_singularity(f.coefficients),JacobiWeightSpace(-.5,-.5,Interval())))
        else
            cf = integrate(f)
            last(cf) - first(cf)
        end
    end
end




## identity

function identity_fun(S::MappedSpace)
    sf=fromcanonical(S,Fun(identity,S.space))
    if isa(space(sf),JacobiWeightSpace)
        Fun(coefficients(sf),JacobiWeightSpace(sf.space.α,sf.space.β,S))
    else
         @assert isa(space(sf),S.space)
         Fun(coefficients(sf),S)
    end
end



## Operators

function addentries!{S1<:MappedSpace,S2<:MappedSpace}(M::Multiplication{S1,S2},A::ShiftArray,kr::Range)
    @assert domain(M.f)==domain(M.space)
    mf=Fun(coefficients(M.f),space(M.f).space)
    addentries!(Multiplication(mf,M.space.space),A,kr)
end

