# ################################################################################
# ###  Introduction to Scientific Programming and Machine Learning with Julia  ###
# ###                                                                          ###
# ### Run each script on a new clean Julia session                             ###
# ### GitHub: https://github.com/sylvaticus/IntroSPMLJuliaCourse               ###
# ### Licence (apply to all material of the course: scripts, videos, quizes,..)###
# ### Creative Commons By Attribution (CC BY 4.0), Antonello Lobianco          ###
# ################################################################################


# # 0302 - The Perceptron algorithm for linear classification 

# ## Some stuff to set-up the environment..

cd(@__DIR__)    
using Pkg      
Pkg.activate(".")  
## If using a Julia version different than 1.10 please uncomment and run the following line (the guarantee of reproducibility will however be lost)
## Pkg.resolve()     
Pkg.instantiate()
using Random
Random.seed!(123)

# ## Perceptron elementary operations

using StatsPlots
function plot2DClassifierWithData(X,y,θ;d1=1,d2=2,origin=false,pid=1)
    colors = [y == -1 ? "red" : "green" for y in y]
    labels = [y == -1 ? "-1" : "+1" for y in y]
    minD1,maxD1 = extrema(X[:,d1])
    minD2,maxD2 = extrema(X[:,d2])
    myplot = scatter(X[:,d1],X[:,d2], colour=colors, title="Linear classifier in 2D",xlabel="Dimx: $d1", ylabel="Dimy: $d2", group=labels)
    constTerm = 0.0
    if !origin
        d1 += 1
        d2 += 1
        constTerm = -θ[1]/θ[d2] 
    end
    d2Class(x) = constTerm -x * θ[d1]/θ[d2]
    if θ[d2] == 0
        vline!([0], color= "blue",label="",linewidth=5)
    else
        plot!(d2Class,min(θ[d1],minD1),max(maxD1,θ[d1]), color= "blue",label="",linewidth=5)
    end
    plot!([0,θ[d1]],[0,θ[d2]],arrow=true,color=:black,linewidth=2,label="")
    display(myplot)
    savefig("currentPlot$(pid).svg");
end
isClassificationError(θ,y,x) =  y * (θ' * x) <= eps()
perceptronUpdate(θ,y,x)      = return θ .+ y .* x 

X = [ 2 4
     -6 1]
y = [-1,-1]
θ₀ = [0,0]
θ = θ₀

ϵ = isClassificationError(θ,y[1],X[1,:])
θ = perceptronUpdate(θ,y[1],X[1,:])
plot2DClassifierWithData(X,y,θ,origin=true,pid=1)
# ![](currentPlot1.svg)
ϵ = isClassificationError(θ,y[1],X[1,:])
ϵ = isClassificationError(θ,y[2],X[2,:])
θ = perceptronUpdate(θ,y[2],X[2,:])
plot2DClassifierWithData(X,y,θ,origin=true,pid=2)
# ![](currentPlot2.svg)
ϵ = isClassificationError(θ,y[2],X[2,:])
ϵ = isClassificationError(θ,y[1],X[1,:])

X = [ 2 4
     1 -2]
θ = θ₀

ϵ = isClassificationError(θ,y[1],X[1,:])
θ = perceptronUpdate(θ,y[1],X[1,:])
plot2DClassifierWithData(X,y,θ, origin=true,pid=3)
# ![](currentPlot3.svg)
ϵ = isClassificationError(θ,y[1],X[1,:])
ϵ = isClassificationError(θ,y[2],X[2,:])
θ = perceptronUpdate(θ,y[2],X[2,:])
plot2DClassifierWithData(X,y,θ, origin=true,pid=4)
# ![](currentPlot4.svg)
ϵ = isClassificationError(θ,y[1],X[1,:])
ϵ = isClassificationError(θ,y[2],X[2,:])
θ = perceptronUpdate(θ,y[2],X[2,:])
plot2DClassifierWithData(X,y,θ,origin=true,pid=5)
# ![](currentPlot5.svg)
ϵ = isClassificationError(θ,y[1],X[1,:])
ϵ = isClassificationError(θ,y[2],X[2,:])
θ

X = [ 2 4
     -2 2]
y = [-1,1]     
θ = θ₀
ϵ = isClassificationError(θ,y[1],X[1,:])
θ = perceptronUpdate(θ,y[1],X[1,:])
plot2DClassifierWithData(X,y,θ, origin=true,pid=6)
# ![](currentPlot6.svg)
ϵ = isClassificationError(θ,y[2],X[2,:])
θ = perceptronUpdate(θ,y[2],X[2,:])
plot2DClassifierWithData(X,y,θ,origin=true,pid=7)
# ![](currentPlot7.svg)

# ## The complete algorithm

# !!! tip
#     The algorithm implemented from scratch in this page form the core of the [`PerceptronClassifier`](https://sylvaticus.github.io/BetaML.jl/stable/Perceptron.html#BetaML.Perceptron.PerceptronClassifier) model in `BetaML`, a multiclass linear classifier.

function perceptronOrigin(X,y,epochs=1;verbose=false)
    (nR,nD) = size(X)
    local θ = zeros(nD)
    for t in 1:epochs
        for n in 1:nR
            if verbose
                println("$n: X[n,:] \t θ: $θ")
            end
            if isClassificationError(θ,y[n],X[n,:])
                θ = perceptronUpdate(θ,y[n],X[n,:])
                if verbose
                    println("**update! New theta: $θ")
                end
            end
        end
    end
    return θ
end
θopt =  perceptronOrigin(X,y,verbose=true)
plot2DClassifierWithData(X,y,θopt, origin=true,pid=8)
# ![](currentPlot8.svg)

# ## Loading binary supervised data

using BetaML, DelimitedFiles
baseDir          = joinpath(dirname(pathof(BetaML)),"..","test","data")
perceptronData   = readdlm(joinpath(dirname(pathof(BetaML)),"..","test","data","binary2DData.csv"),'\t')

nR = size(perceptronData,1)

idx = shuffle(1:nR)
perceptronData = perceptronData[idx,:]
X                = copy(perceptronData[:,[2,3]])
y                = convert(Array{Int64,1},copy(perceptronData[:,1]))

# ## A better organisation

# Now we rewrite the perceptron algorithm setting all the parameters in a structure and using what could be a generic interface for any supervised model. This is the approach used by most ML libraries.
# We will see how to measure the classification error and as we are here we add the constant term with the constant addition to the data trick (note that editing every time the feature matrix is _NOT_ efficient and we do it here only for simplicity. A better way is to explicitly model the perceptron model with a constant parameter.)


abstract type SupervisedModel end
abstract type TrainingOptions end

mutable struct Perceptron <: SupervisedModel
    θ::Vector{Float64}
end

mutable struct PerceptronTrainingOptions <: TrainingOptions
    epochs::Int64
    verbose::Bool
    shuffle::Bool
    function PerceptronTrainingOptions(;epochs=1,verbose=false,shuffle=false)
        return new(epochs,verbose,shuffle)
    end
end


function predict(model::Perceptron,x::AbstractVector)
    x = vcat(1.0,x)
    x' * model.θ > eps() ? (return 1) : (return -1)
end

function predict(model::Perceptron,X::AbstractMatrix)
    return [predict(model,r) for r in eachrow(X)]
end


function update!(model::Perceptron,X::Vector,y)
    X       = vcat(1.0,X)
    model.θ = model.θ .+ y .* X
    return model.θ
end

function train!(model::Perceptron,X,y,ops=PerceptronTrainingOptions()::TrainingOptions)
    epochs  = ops.epochs
    verbose = ops.verbose
    (nR,nD) = size(X)
    nD += 1
    for t in 1:epochs
        errors = 0
        if ops.shuffle   # more efficient !
          idx = shuffle(1:nR)
          X = X[idx,:]
          y = y[idx]
        end
        for n in 1:nR
            if verbose
                println("$n: X[n,:] \t θ: $(model.θ)")
            end
            if  predict(model,X[n,:]) != y[n]
                errors += 1
                θ = update!(model,X[n,:],y[n])
                if verbose
                    println("**update! New theta: $(model.θ)")
                end
            end
        end
        if verbose
            println("Epoch $t errors: $errors")
        end
    end
    return model.θ
end

# ## Testing the Perceptron algorithm

m   = Perceptron(zeros(size(X,2)+1))
ops = PerceptronTrainingOptions()
train!(m,X,y,ops)
plot2DClassifierWithData(X,y,m.θ,pid=9)
# ![](currentPlot9.svg)

ŷ = predict(m,X)
inSampleAccuracy = sum(y .== ŷ)/length(y)

# Let's see if shuffling and increasing epochs we improve the accuracy....
ops = PerceptronTrainingOptions(verbose=false,epochs=5,shuffle=true)
m   = Perceptron(zeros(size(X,2)+1))
train!(m,X,y,ops)
plot2DClassifierWithData(X,y,m.θ,pid=10)
# ![](currentPlot10.svg)
ŷ = predict(m,X)
inSampleAccuracy = sum(y .== ŷ)/length(y)


# ## Cross-validation and hyperparameters optimisation 

# Let's see now using separate training/validation
# We use the BetaML `partition()` function
((xtrain,xtest),(ytrain,ytest)) = partition([X,y],[0.6,0.4])
m             = Perceptron(zeros(size(X,2)+1))
ops           = PerceptronTrainingOptions(epochs=5,shuffle=true)
train!(m,xtrain,ytrain,ops)
plot2DClassifierWithData(xtrain,ytrain,m.θ,pid=11)
# ![](currentPlot11.svg)
ŷtrain = predict(m,xtrain)
trainAccuracy = accuracy(ŷtrain,ytrain)
sum(ytrain  .== ŷtrain)/length(ytrain)
## @edit accuracy(ŷtrain,ytrain)
ŷtest         = predict(m,xtest)
testAccuracy  = accuracy(ŷtest,ytest)
plot2DClassifierWithData(xtest,ytest,m.θ,pid=12)
# ![](currentPlot12.svg)
cfOut = ConfusionMatrix()
fit!(cfOut,ŷtest,ytest)
print(cfOut)
res = info(cfOut)
heatmap(string.(res["categories"]),string.(res["categories"]),res["normalised_scores"],seriescolor=cgrad([:white,:blue]),xlabel="Predicted",ylabel="Actual", title="Confusion Matrix (normalised scores)")

# Let's use CrossValidation 
((xtrain,xvalidation,xtest),(ytrain,yvalidation,ytest)) = partition([X,y],[0.6,0.2,0.2])
## Very few records..... let's go back to using only two subsets but with CrossValidation 
((xtrain,xtest),(ytrain,ytest)) = partition([X,y],[0.6,0.4])

sampler    = KFold(nsplits=10)

ops     = PerceptronTrainingOptions(epochs=10,shuffle=true)
(acc,σ) = cross_validation([xtrain,ytrain],sampler) do trainData,valData,rng
                (xtrain,ytrain) = trainData; (xval,yval) = valData
                m               = Perceptron(zeros(size(xtrain,2)+1))
                train!(m,xtrain,ytrain,ops)
                ŷval         = predict(m,xval)
                valAccuracy  = accuracy(ŷval,yval)
                return valAccuracy
            end
            

epochsSet  = 1:10:301
shuffleSet = [false,true]

bestE       = 0
bestShuffle = false
bestAcc     = 0.0

for e in epochsSet, s in shuffleSet
    global bestE, bestShuffle, bestAcc
    local acc
    local ops  = PerceptronTrainingOptions(epochs=e,shuffle=s)
    (acc,_)    = cross_validation([xtrain,ytrain],sampler) do trainData,valData,rng
                    (xtrain,ytrain) = trainData; (xval,yval) = valData
                    m               = Perceptron(zeros(size(xtrain,2)+1))
                    train!(m,xtrain,ytrain,ops)
                    ŷval            = predict(m,xval)
                    valAccuracy     = accuracy(ŷval,yval)
                    return valAccuracy
                end
    if acc > bestAcc
        bestAcc     = acc
        bestE       = e
        bestShuffle = s
    end
end

bestAcc
bestE
bestShuffle

ops = PerceptronTrainingOptions(epochs=bestE,shuffle=bestShuffle)
m   = Perceptron(zeros(size(xtest,2)+1))
train!(m,xtrain,ytrain,ops)
ŷtest           = predict(m,xtest)
testAccuracy    = accuracy(ŷtest,ytest)

plot2DClassifierWithData(xtest,ytest,m.θ,pid=13)
# ![](currentPlot13.svg)
