using ApproxFun, BlockBandedMatrices,  Compat.Test
    import ApproxFun: Multiplication,InterlaceOperator, Block, ∞
    import ApproxFun: testfunctional, testbandedoperator, testraggedbelowoperator, testinfoperator, testblockbandedoperator

@testset "Operator" begin
    # test row/colstarts
    testfunctional(Evaluation(Ultraspherical(1),0.1))
    testbandedoperator(Derivative(Ultraspherical(1)))
    testfunctional(Evaluation(Chebyshev(),0.1,1))
    testfunctional(Evaluation(Chebyshev(),0.1,1)-Evaluation(Chebyshev(),0.1,1))

    let f = Fun(cos)
        @test (Evaluation(Chebyshev(),0.1,1)*f)(0.1)  ≈ f'(0.1)
    end


    # test fast copy is consistent with getindex


    C=ToeplitzOperator([1.,2.,3.],[4.,5.,6.])

    @time testbandedoperator(C)

    @test full(C[1:5,1:5])  ≈  [4.0 5.0 6.0 0.0  0.0
                                         1.0 4.0 5.0 6.0 0.0
                                         2.0 1.0 4.0 5.0 6.0
                                         3.0 2.0 1.0 4.0 5.0
                                         0.0 3.0 2.0 1.0 4.0]

    C=Conversion(Ultraspherical(1),Ultraspherical(2))

    testbandedoperator(C)

    @test full(C[1:5,1:5])  ≈   [1.0 0.0 -0.3333333333333333 0.0  0.0
                                          0.0 0.5  0.0               -0.25 0.0
                                          0.0 0.0  0.3333333333333333 0.0 -0.2
                                          0.0 0.0  0.0                0.25 0.0
                                          0.0 0.0  0.0                0.0  0.2]




    @time for M in (HankelOperator([1.,2.,3.,4.,5.,6.,7.]),
                Multiplication(Fun(Chebyshev(),[1.,2.,3.]),Chebyshev()))
        testbandedoperator(M)
    end



    d=Interval(-10.,5.);
    S=Chebyshev(d)


    @test norm(Fun(Fun(Fun(exp,S),Ultraspherical(2,d)),S)-Fun(exp,S)) < 100eps()


    @test copy(view(Derivative(Ultraspherical(1)),1:2,1:2))[1,2] ≈ Derivative(Ultraspherical(1))[1,2]
    @test exp(0.1) ≈ (Derivative()*Fun(exp,Ultraspherical(1)))(0.1)


    f=Fun(exp)
    d=domain(f)
    Q=Integral(d)
    D=Derivative(d)

    @time testbandedoperator(Q)

    @test norm((Q+I)*f-(integrate(f)+f)) < 100eps()
    @test norm((Q)*f-(integrate(f))) < 100eps()

    x=Fun(identity)
    X=Multiplication(x,space(x))

    testbandedoperator(X)

    d=Interval()
    A=Conversion(Chebyshev(d),Ultraspherical(2,d))

    @test AbstractMatrix(view(A.op, Block.(1:3), Block.(1:3))) isa BlockBandedMatrix
    testbandedoperator(A)

    @test norm(A\Fun(x.*f,rangespace(A))-(x.*f)) < 100eps()

    @test norm((Conversion(Chebyshev(d),Ultraspherical(2,d))\(D^2*f))-f'') < 100eps()

    @test norm(X*f-(x.*f)) < 100eps()

    A=Conversion(Chebyshev(d),Ultraspherical(2,d))*X
    @time testbandedoperator(A)



    @test norm((A_mul_B_coefficients(A,f.coefficients))-coefficients(x.*f,rangespace(A))) < 100eps()


    ## Special functions

    x=Fun(identity)
    @test norm(cos(x)-Fun(cos))<10eps()
    @test norm(sin(x)-Fun(sin))<10eps()
    @test norm(exp(x)-Fun(exp))<10eps()
    @test norm(sin(x)./x-Fun(x->sinc(x/π)))<100eps()


    P=ApproxFun.PermutationOperator([2,1])

    testbandedoperator(P)

    @test P[1:4,1:4] ≈ [0 1 0 0; 1 0 0 0; 0 0 0 1; 0 0 1 0]



    ## Periodic


    d=PeriodicInterval(0.,2π)
    a=Fun(t-> 1+sin(cos(10t)),d)
    D=Derivative(d)
    L=D+a

    @time testbandedoperator(D)
    @time testbandedoperator(Multiplication(a,Space(d)))


    f=Fun(t->exp(sin(t)),d)
    u=L\f

    @test norm(L*u-f) < 100eps()

    d=PeriodicInterval(0.,2π)
    a1=Fun(t->sin(cos(t/2)^2),d)
    a0=Fun(t->cos(12sin(t)),d)
    D=Derivative(d)
    L=D^2+a1*D+a0

    @time testbandedoperator(L)

    f=Fun(space(a1),[1,2,3,4,5])

    testbandedoperator(Multiplication(a0,Fourier(0..2π)))

    @test (Multiplication(a0,Fourier(0..2π))*f)(0.1)  ≈ (a0(0.1)*f(0.1))
    @test ((Multiplication(a1,Fourier(0..2π))*D)*f)(0.1)  ≈ (a1(0.1)*f'(0.1))
    @test (L.ops[1]*f)(0.1) ≈ f''(0.1)
    @test (L.ops[2]*f)(0.1) ≈ a1(0.1)*f'(0.1)
    @test (L.ops[3]*f)(0.1) ≈ a0(0.1)*f(0.1)
    @test (L*f)(0.1) ≈ f''(0.1)+a1(0.1)*f'(0.1)+a0(0.1)*f(0.1)

    f=Fun(t->exp(cos(2t)),d)
    u=L\f

    @test norm(L*u-f) < 1000eps()




    ## Check mixed

    d = Interval()
    D = Derivative(d)
    x = Fun(identity,d)
    A = D*(x*D)
    B = D+x*D^2
    C = x*D^2+D

    testbandedoperator(A)
    testbandedoperator(B)
    testbandedoperator(C)
    @time testbandedoperator(x*D)

    f=Fun(exp)
    @test (A.ops[end]*f)(0.1) ≈ f'(0.1)
    @test ((x*D)*f)(0.1) ≈ 0.1*f'(0.1)
    @test (A*f)(0.1) ≈ f'(0.1)+0.1*f''(0.1)
    @test (B*f)(0.1) ≈ f'(0.1)+0.1*f''(0.1)
    @test (C*f)(0.1) ≈ f'(0.1)+0.1*f''(0.1)


    testbandedoperator(A-B)
    testbandedoperator(B-A)
    testbandedoperator(A-C)

    @test norm((A-B)[1:10,1:10]|>full) < eps()
    @test norm((B-A)[1:10,1:10]|>full) < eps()
    @test norm((A-C)[1:10,1:10]|>full) < eps()
    @test norm((C-A)[1:10,1:10]|>full) < eps()
    @test norm((C-B)[1:10,1:10]|>full) < eps()
    @test norm((B-C)[1:10,1:10]|>full) < eps()



    ## Cached operator
    @test cache(Derivative(Chebyshev(),2))[1,1] == 0


    S=Chebyshev()
    D=Derivative(S)
    @time for padding = [true,false]
      co=ApproxFun.CachedOperator(D,ApproxFun.RaggedMatrix(Float64[],Int[1],0),(0,0),domainspace(D),rangespace(D),bandinds(D),padding) #initialise with empty RaggedMatrix
      @test co[1:20,1:10] == D[1:20,1:10]
      @test size(co.data) == (20,10)
      ApproxFun.resizedata!(co,10,30)
      @test size(co.data)[2] == 30 && size(co.data)[1] ≥ 20
    end

    ## Reverse


    testbandedoperator(ApproxFun.Reverse(Chebyshev()))
    testbandedoperator(ApproxFun.ReverseOrientation(Chebyshev()))

    @test ApproxFun.Reverse(Chebyshev())*Fun(exp) ≈ Fun(x->exp(-x))
    @test ApproxFun.ReverseOrientation(Chebyshev())*Fun(exp) ≈ Fun(exp,1..(-1))


    @test norm(ApproxFun.Reverse(Fourier())*Fun(t->cos(cos(t-0.2)-0.1),Fourier()) - Fun(t->cos(cos(-t-0.2)-0.1),Fourier())) < 10eps()
    @test norm(ApproxFun.ReverseOrientation(Fourier())*Fun(t->cos(cos(t-0.2)-0.1),Fourier()) - Fun(t->cos(cos(t-0.2)-0.1),Fourier(PeriodicInterval(2π,0)))) < 10eps()





    ## Sub interval
    f = Fun(exp)

    D = Derivative(Chebyshev())
    u = D[:,2:end] \ f
    @test norm(u'-f) < 10eps()
    @test u(0.1) ≈ exp(0.1)-f.coefficients[1]


    u = D[1:end,2:end] \ f
    @test u(0.1) ≈ exp(0.1)-f.coefficients[1]

    u = D[1:ApproxFun.∞,2:ApproxFun.∞] \ f
    @test u(0.1) ≈ exp(0.1)-f.coefficients[1]




    A = InterlaceOperator(Diagonal([eye(2),Derivative(Chebyshev())]))
    @test A[Block(1):Block(2), Block(1):Block(2)] isa BlockBandedMatrix

    @test Matrix(view(A, Block(1), Block(1))) == A[1:3,1:3]
    @test Matrix(view(A, Block(1):Block(2), Block(1):Block(2))) == A[1:4,1:4]
    testblockbandedoperator(A)


    ## Projection
    ## SubSpace test

    S=Chebyshev()
    SS = S|(2:5)
    @test ApproxFun.block(SS,3) == Block(4)

    for C in (eye(S)[3:end,:], eye(S)[3:end,1:end])
        @test ApproxFun.domaindimension(domainspace(C)) == 1
        @test union(S,domainspace(C)) == S

        B=Dirichlet(S)

        Ai=[B;C]

        @test ApproxFun.colstop(Ai,1) == 2

        x=Fun()
        f=exp(x)
        u=[B;C]\[[0.,0.],f]

        @test abs(u(-1)) ≤ 10eps()
        @test abs(u(1)) ≤ 10eps()


        f=(1-x^2)*exp(x)
        u=[B;C]\[[0.,0.],f]

        @test u ≈ f
    end



    ## Test Zero operator has correct bandinds

    Z=ApproxFun.ZeroOperator(Chebyshev())
    @test ApproxFun.bandinds(Z) == ApproxFun.bandinds(Z+Z)


    ## Issue 407
    x = Fun()
    B = [1 ldirichlet()]
    @test (B*[1;x])[1] == Fun(ConstantSpace(ApproxFun.Point(-1.0)),[0.0])



    ## views of views
    A = Derivative(Chebyshev()) + I
    B = A[1:2:∞,1:2:∞]
    C = B[2:∞,3:∞]
    @test A[3:2:∞,5:2:∞] == C
end
