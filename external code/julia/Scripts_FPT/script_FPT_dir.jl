# NEEDED LIBRARIES
using Distributions
using SpecialFunctions
using Interpolations
using GSL
using QuadGK

function initialize_ω(mode::String, t, ω_0, ω_1=0.0, ω_2=0.0)
    if mode=="Constant"
        return ω_0
    elseif mode=="Linear"
        return ω_0 + ω_1*t
    elseif mode=="Quadratic"
        return ω_0 + ω_1*t + ω_2*t^2
    else
        return 0.0
    end
end

function initialize_Ω(mode::String, t, ω_0, ω_1=0.0, ω_2=0.0)
    if mode=="Constant"
        return ω_0*t
    elseif mode=="Linear"
        return ω_0*t + (1/2)*ω_1*t^2
    elseif mode=="Quadratic"
        return ω_0*t + (1/2)*ω_1*t^2 + (1/3)*ω_2*t^3
    else
        return 0.0
    end
end

function initialize_τ(mode::String, t, ω, Ω, ω_0, ω_1=0.0, ω_2=0.0)
    if mode=="Constant"
        return (1-exp(-2*Ω(t)))/2/ω(t)
    elseif mode=="Linear"
        return (1/√(ω_1)) *( (dawson(ω(t)/√(ω_1))) - exp(-2*Ω(t))*dawson(ω_0/√(ω_1)) )  # ω_1 cannot be set to 0!!!!
    elseif mode=="Quadratic"
        t_step = t/Nsteps
        t_support = 0.0:t_step:1.2*t
        τ_space = zeros(Float64, length(t_support))
        integrand(s) = exp(-2*(Ω(t)-Ω(s)))
        for (i, s) in enumerate(t_support)
            τ_space[i] = quadgk(integrand, 0.0, s, rtol=1e-8)[1]
        end
        dummy_function = cubic_spline_interpolation(t_support, τ_space)
        return dummy_function(t)
    else
        return 1.0
    end
end

Nsteps = 10^3

# print("Welcome, this script will help you plotting the distribution of the first passage in the interval [0,t].\n
#     First of all, please enter the value of t ")
total_time = parse(Float64, ARGS[1]) #parse(Float64, readline())

# print("The interval [0,t] is discretized in N small steps. Please enter the value of N ")
N = parse(Float64, ARGS[2])#parse(Float64, readline())
t_step = total_time/N
t_space = collect(0.00:t_step:total_time)

# print("Please enter the value of the parameter A≡γ/2k_BT. A = ")
A_list = parse.(Float64, split(ARGS[3], ","))# parse(Float64, readline())
# print("Please enter the value of the initial position x_0 ")
x_0_list = parse.(Float64, split(ARGS[4], ","))#parse(Float64, readline())
# print("Let us define the frequency ω(t)=κ(t)/γ, i.e. the stiffness divided by the friction.\n
#     You can choose between 'Constant', 'Linear' and 'Quadratic' protocol. \n Enter the protocol desired ")
control_string = ARGS[5]#readline()
if control_string == "Constant"
    # print("Then your frequency is ω(t)=ω_0. Please enter ω_0 ")
    #let's initialize the lists that were not used
    ω_0_list = ω_1_list = ω_2_list = parse.(Float64, split(ARGS[6], ","))# parse(Float64, readline())
elseif control_string == "Linear"
    print("Then your frequency is ω(t)=ω_0+ω_1*t. Please enter ω_0 ")
    ω_0_list = parse.(Float64, split(ARGS[6], ","))
    print("Please enter ω_1 ")
    ω_1_list = ω_2_list = parse.(Float64, split(ARGS[7], ","))
elseif control_string == "Quadratic"
    print("Then your frequency is ω(t)=ω_0+ω_1*t+ω_2*t*t. Please enter ω_0 ")
    ω_0_list = parse.(Float64, split(ARGS[6], ","))
    print("Please enter ω_1 ")
    ω_1_list = parse.(Float64, split(ARGS[7], ","))
    print("Please enter ω_2 ")
    ω_2_list = parse.(Float64, split(ARGS[8], ","))
else
    print("Wrong entry. Run the program again")
end

if control_string == "Constant" || control_string == "Linear" || control_string == "Quadratic"
    # ω(t) = initialize_ω(control_string, t)
    # Ω(t) = initialize_Ω(control_string, t)
    # τ(t) = initialize_τ(control_string, t)
    # ℘(t, x_0) = √(A)* abs(x_0)*exp(-Ω(t))/√(2*π*(τ(t))^3) * exp(-A*(x_0^2*exp(-2*Ω(t)))/(2*τ(t)))
    # FPTD_vector = ℘.(t_space, x_0)
    
    # file_path = "C:/Git/bioTweezer_fpga/external code/python/result.csv"

    # open(file_path, "w") do io
    #     # write(io, string("Parameters: ", control_string, " protocol, x_0=", string(x_0), ", t=", string(total_time), ", A=", 
    #     #         string(A), "\n"))
    #     write(io, "time axis,first-passage time distribution\n")
    #     for i=1:length(t_space)
    #         write(io, string(string(t_space[i]), ",", string(FPTD_vector[i]), "\n"))
    #     end
    # end
    FPTD_matrix = []
    # (A, x_0, ω_0, ω_1, ω_2) = (0.0, 0.0, 0.0, 0.0, 0.0)
    for (i, (A, x_0, ω_0, ω_1, ω_2)) in enumerate(zip(A_list, x_0_list, ω_0_list, ω_1_list, ω_2_list))
        ω(t) = initialize_ω(control_string, t, ω_0, ω_1, ω_2)
        Ω(t) = initialize_Ω(control_string, t, ω_0, ω_1, ω_2)
        τ(t) = initialize_τ(control_string, t, ω, Ω, ω_0, ω_1, ω_2)
        ℘(t, x_0) = √(A)* abs(x_0)*exp(-Ω(t))/√(2*π*(τ(t))^3) * exp(-A*(x_0^2*exp(-2*Ω(t)))/(2*τ(t)))
        FPTD_vector = ℘.(t_space, x_0)
        push!(FPTD_matrix, FPTD_vector)
    end

    file_path = "C:/Git/bioTweezer_fpga/external code/python/result.csv"

    open(file_path, "w") do io
        header = "time axis," * join(["execution_$i" for i in 1:length(A_list)], ",") * "\n"
        write(io, header)
        for i in 1:length(t_space)
            row = string(t_space[i]) * "," * join([string(FPTD_matrix[j][i]) for j in 1:length(A_list)], ",") * "\n"
            write(io, row)
        end
    end
end