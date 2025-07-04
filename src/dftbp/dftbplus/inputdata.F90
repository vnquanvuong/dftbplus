!--------------------------------------------------------------------------------------------------!
!  DFTB+: general package for performing fast atomistic simulations                                !
!  Copyright (C) 2006 - 2025  DFTB+ developers group                                               !
!                                                                                                  !
!  See the LICENSE file for terms of usage and distribution.                                       !
!--------------------------------------------------------------------------------------------------!

#:include 'common.fypp'

!> Contains data type representing the input data for DFTB.
module dftbp_dftbplus_inputdata
  use dftbp_common_accuracy, only : dp, lc
  use dftbp_common_hamiltoniantypes, only : hamiltonianTypes
  use dftbp_derivs_perturb, only : TPerturbInp
  use dftbp_dftb_dftbplusu, only : TDftbUInp
  use dftbp_dftb_dispersions, only : TDispersionInp
  use dftbp_dftb_elecconstraints, only : TElecConstraintInp
  use dftbp_dftb_elstatpot, only : TElStatPotentialsInp
  use dftbp_dftb_etemp, only : fillingTypes
  use dftbp_dftb_extfields, only : TElecFieldInput
  use dftbp_dftb_h5correction, only : TH5CorrectionInput
  use dftbp_dftb_pmlocalisation, only : TPipekMezeyInp
  use dftbp_dftb_potentials, only : TAtomExtPotInput
  use dftbp_dftb_repulsive_chimesrep, only : TChimesRepInp
  use dftbp_dftb_repulsive_pairrepulsive, only : TPairRepulsiveItem
  use dftbp_dftb_slakocont, only : TSlakoCont
  use dftbp_dftb_mdftb, only : TMdftbAtomicIntegrals
  use dftbp_dftbplus_input_geoopt, only : TGeoOptInput
  use dftbp_elecsolvers_elecsolvers, only : TElectronicSolverInp
  use dftbp_extlibs_poisson, only : TPoissonInfo
  use dftbp_extlibs_tblite, only : TTBLiteInput
  use dftbp_md_mdcommon, only : TMDOutput
  use dftbp_md_xlbomd, only : TXLBOMDInp
  use dftbp_mixer_factory, only : TMixerInput
  use dftbp_reks_reks, only : TReksInp
  use dftbp_solvation_cm5, only : TCM5Input
  use dftbp_solvation_solvinput, only : TSolvationInp
  use dftbp_timedep_linresp, only : TLinrespini
  use dftbp_timedep_pprpa, only : TppRPAcal
  use dftbp_timedep_timeprop, only : TElecDynamicsInp
  use dftbp_type_commontypes, only : TOrbitals
  use dftbp_type_linkedlist, only : destruct, TListIntR1
  use dftbp_type_typegeometry, only : TGeometry
  use dftbp_type_wrappedintr, only : TWrappedInt1
#:if WITH_SOCKETS
  use dftbp_io_ipisocket, only : IpiSocketCommInp
#:endif
#:if WITH_TRANSPORT
  use dftbp_transport_negfvars, only : TNEGFGreenDensInfo, TNEGFTunDos, TTransPar
#:endif
  implicit none

  private
  public :: TControl, TSlater, TInputData, TParallelOpts
  public :: TBlacsOpts
  public :: THybridXcInp
  public :: init, destruct
  public :: TNEGFInfo


  !> Contains Blacs specific options.
  type :: TBlacsOpts

    !> Block size for matrix rows and columns.
    integer :: blockSize

  end type TBlacsOpts


  !> Contains the parallel options
  type :: TParallelOpts

    !> Number of processor groups
    integer :: nGroup

    !> Blacs options
    type(TBlacsOpts) :: blacsOpts

    !> Whether hybrid parallelisation is enable
    logical :: tOmpThreads

  end type TParallelOpts


  !> LBFGS input settings
  type TLbfgsInput

    !> Number of stored steps
    integer :: memory

    !> Is a line search followed along quasi-Newton directions
    logical :: isLineSearch

    !> Should the quasi-Newton step be limited?
    logical :: MaxQNStep

    !> If performing line search, should the original implementation be used
    logical :: isOldLS

  end type TLbfgsInput


  !> Hybrid xc-functional input
  type THybridXcInp

    !> Threshold for integral screening
    real(dp) :: screeningThreshold

    !> Reduction of cutoff in spatial screening
    real(dp) :: cutoffRed

    !> Separation parameter
    real(dp) :: omega

    !> CAM alpha parameter
    real(dp) :: camAlpha

    !> CAM beta parameter
    real(dp) :: camBeta

    !> Choice of hybrid xc-functional algorithm to build Hamiltonian
    integer :: hybridXcAlg

    !> Hybrid xc-functional type, as extracted from SK-file(s)
    integer :: hybridXcType

    !> Choice of range separation gamma function type (periodic cases only)
    integer :: gammaType

    !> Cutoff for real-space g-summation
    real(dp), allocatable :: gSummationCutoff

    !> Number of unit cells along each supercell folding direction to subtract from minimum image
    !! convention (MIC) Wigner-Seitz cell construction
    integer, allocatable :: wignerSeitzReduction

    !> Coulomb truncation cutoff of Gamma electrostatics
    real(dp), allocatable :: gammaCutoff

  end type THybridXcInp


  !> Main control data for program as extracted by the parser
  type TControl

    !> Choice of electronic hamiltonian
    integer :: hamiltonian = hamiltonianTypes%none

    !> Random number generator seed
    integer :: iSeed = 0

    !> Maximum force for geometry convergence
    real(dp) :: maxForce = 0.0_dp

    !> SCC calculation?
    logical :: tScc = .false.

    !> l-shell resolved SCC
    logical :: tShellResolved = .false.

    !> SCC tolerance
    real(dp) :: sccTol = 0.0_dp

    !> Read starting charges from disc
    logical :: tReadChrg = .false.

    logical :: tSkipChrgChecksum = .false.

    !> Disc charges are stored as ascii or binary files
    logical :: tReadChrgAscii = .true.

    !> Write charges to disc
    logical :: tWriteCharges = .true.

    !> Disc charges should be written as ascii or binary files
    logical :: tWriteChrgAscii = .true.

    !> Should probably be packaged
    logical :: isGeoOpt = .false.

    !> Coordinate optimisation
    logical :: tCoordOpt = .false.

    !> Maximum line search step for atoms
    real(dp) :: maxAtomDisp = 0.2_dp

    !> Should probably be packaged
    logical :: tLatOpt = .false.

    !> Fix angles during lattice optimisation
    logical :: tLatOptFixAng = .false.

    !> Fix lengths of specified vectors
    logical :: tLatOptFixLen(3) = .false.

    !> Isotropically scale instead
    logical :: tLatOptIsotropic = .false.

    !> Maximum possible linesearch step
    real(dp) :: maxLatDisp = 0.2_dp

    !> Add new geometries at the end of files
    logical :: tAppendGeo = .false.

    !> Use converged SCC charges for properties like forces or charge dependent dispersion
    logical :: isSccConvRequired = .true.

    !> Geometry step
    integer :: iGeoOpt = 0

    !> Used for gDIIS
    real(dp) :: deltaGeoOpt = 0.0_dp

    !> Used for gDIIS
    integer :: iGenGeoOpt = 0

    !> Internal variable for requirement of Mulliken analysis
    logical :: tMulliken = .false.

    !> Printout of Mulliken
    logical :: tPrintMulliken = .false.

    !> Net atomic charges (i.e. on-site only part of Mulliken charges)
    logical :: tNetAtomCharges = .false.

    !> Should net atomic charges be printed
    logical :: tPrintNetAtomCharges = .false.

    !> Input for CM5 corrected Mulliken charges
    type(TCM5Input), allocatable :: cm5Input

    !> Electrostatic potential evaluation and printing
    type(TElStatPotentialsInp), allocatable :: elStatPotentialsInp

    !> Localise electronic states
    logical :: tLocalise = .false.

    !> Input data for Pipek-Mezey localisation
    type(TPipekMezeyInp), allocatable :: pipekMezeyInp

    !> Perturbation theory input data
    type(TPerturbInp), allocatable :: perturbInp

    !> Printing of atom resolved energies
    logical :: tAtomicEnergy = .false.

    !> Print eigenvectors to disc
    logical :: tPrintEigVecs = .false.

    !> Text file of eigenvectors?
    logical :: tPrintEigVecsTxt = .false.

    !> Project eigenvectors spatially
    logical :: tProjEigenvecs = .false.

    !> Evaluate forces
    logical :: tForces = .false.

    !> Evaluate force contributions from the excited state if required and (tForces)
    logical :: tCasidaForces = .false.

    !> Force evaluation method
    integer :: forceType

    !> Output forces
    logical :: tPrintForces = .false.

    !> Method for calculating derivatives
    integer :: iDerivMethod = 0

    !> 1st derivative finite difference step
    real(dp) :: deriv1stDelta = 0.0_dp


    !> Molecular dynamics
    logical :: tMD = .false.

    !> Molecular dynamics data to be recorded as it is accumulated
    type(TMDOutput), allocatable :: mdOutput

    !> Use Plumed
    logical :: tPlumed = .false.

    !> Finite difference derivatives calculation?
    logical :: tDerivs = .false.

    !> Should central cell coordinates be output?
    logical :: tShowFoldedCoord

    real(dp) :: nrChrg = 0.0_dp
    real(dp) :: nrSpinPol = 0.0_dp
    logical :: tSpin = .false.
    logical :: tSpinSharedEf = .false.
    logical :: tSpinOrbit = .false.
    logical :: tDualSpinOrbit = .false.
    logical :: t2Component = .false.

    !> Initial spin pattern
    real(dp), allocatable :: initialSpins(:,:)

    !> Initial charges
    real(dp), allocatable :: initialCharges(:)

    !> Electronic/eigenvalue solver options
    type(TElectronicSolverInp) :: solver

    !> If using the GPU as
    logical :: isDmOnGpu = .false.


    !> Maximum number of self-consistent iterations
    integer :: maxSccIter = 0

    !> Mixer Input data
    type(TMixerInput) :: mixerInp

    integer :: nrMoved = 0
    integer, allocatable :: indMovedAtom(:)
    integer, allocatable :: indDerivAtom(:)
    integer :: nrConstr = 0
    integer, allocatable :: conAtom(:)
    real(dp), allocatable :: conVec(:,:)
    character(lc) :: outFile = ''

    !> Do we have MD velocities
    logical :: tReadMDVelocities = .false.

    !> Initial MD velocities
    real(dp), allocatable :: initialVelocities(:,:)
    real(dp) :: deltaT = 0.0_dp

    real(dp) :: tempAtom = 0.0_dp
    integer :: iThermostat = 0

    !> Whether to initialize internal state of the Nose-Hoover thermostat from input
    logical :: tInitNHC = .false.

    !> Internal state variables for the Nose-Hoover chain thermostat
    real(dp), allocatable :: xnose(:)
    real(dp), allocatable :: vnose(:)
    real(dp), allocatable :: gnose(:)


    !> Whether to shift to a co-moving frame for MD
    logical :: tMDstill
    logical :: tRescale = .false.
    integer, allocatable :: tempMethods(:)
    integer, allocatable :: tempSteps(:)
    real(dp), allocatable :: tempValues(:)
    logical :: tSetFillingTemp = .false.

    real(dp) :: tempElec = 0.0_dp
    logical :: tFixEf = .false.
    real(dp), allocatable :: Ef(:)
    logical :: tFillKSep = .false.
    integer :: iDistribFn = fillingTypes%Fermi
    real(dp) :: wvScale = 0.0_dp

    !> Default chain length for Nose-Hoover
    integer :: nh_npart = 3

    !> Default order of NH integration
    integer :: nh_nys = 3

    !> Default multiple time steps for N-H propagation
    integer :: nh_nc = 1

    integer :: maxRun = -2


    !> Second derivative finite difference step
    real(dp) :: deriv2ndDelta = 0.0_dp

    !> Number of k-points for the calculation
    integer :: nKPoint = 0

    !> The k-points for the system (= 0 for molecular in free space and no symmetries)
    real(dp), allocatable :: kPoint(:,:)

    !> Weights for the k-points
    real(dp), allocatable :: kWeight(:)

    !> Are the k-points not suitable for integrals over the Brillouin zone
    logical :: poorKSampling = .false.

    !> Should an additional check be performed if more than one SCC step is requested
    !! (indicates that the k-point sampling has changed as part of the restart)
    logical :: checkStopHybridCalc = .false.

    !> Coefficients of the lattice vectors in the linear combination for the super lattice vectors
    !! (should be integer values) and shift of the grid along the three small reciprocal lattice
    !! vectors (between 0.0 and 1.0)
    real(dp), allocatable :: supercellFoldingMatrix(:,:)

    !> Three diagonal elements of supercell folding coefficient matrix
    integer, allocatable :: supercellFoldingDiag(:)

    !> Tolerance for helical symmetry determination of acceptable k-points commensurate with the
    !! C_n symmetry
    real(dp) :: helicalSymTol = 1.0E-8_dp

    !> Cell pressure if periodic
    real(dp) :: pressure = 0.0_dp
    logical :: tBarostat = .false.

    !> Use isotropic scaling if barostatting
    logical :: tIsotropic = .true.
    real(dp) :: BarostatStrength = 0.0_dp


    !> Read atomic masses from the input not the SK data
    real(dp), allocatable :: masses(:)


    !> Spin constants
    real(dp), allocatable :: spinW(:,:,:)

    !> Customised Hubbard U values
    real(dp), allocatable :: hubbU(:,:)

    !> Spin-orbit constants
    real(dp), allocatable :: xi(:,:)

    !> DFTB+U input, if present
    type(TDftbUInp), allocatable :: dftbUInp

    !> Correction to energy from on-site matrix elements
    real(dp), allocatable :: onSiteElements(:,:,:,:)

    !> Correction to dipole momements on-site matrix elements
    real(dp), allocatable :: onSiteDipole(:,:)

    !> Number of external charges
    integer :: nExtChrg = 0

    !> External charge values and locations
    real(dp), allocatable :: extChrg(:,:)

    !> Finite charge width if needed
    real(dp), allocatable :: extChrgBlurWidth(:)

    !> Homogeneous external electric field
    type(TElecFieldInput), allocatable :: electricField

    !> Potential(s) at atomic sites
    type(TAtomExtPotInput), allocatable :: atomicExtPotential

    !> Projection of eigenvectors
    type(TListIntR1) :: iAtInRegion
    logical, allocatable :: tShellResInRegion(:)
    logical, allocatable :: tOrbResInRegion(:)
    character(lc), allocatable :: RegionLabel(:)

    !> H short range damping
    logical :: tDampH = .false.
    real(dp) :: dampExp = 0.0_dp

    type(TH5CorrectionInput), allocatable :: h5Input

    !> Halogen X correction
    logical :: tHalogenX = .false.

    !> Old repulsive
    logical :: useBuggyRepSum


    !> Old kinetic energy stress contribution in MD
    logical :: useBuggyKEStress = .false.

    !> Ewald alpha
    real(dp) :: ewaldAlpha = 0.0_dp

    !> Ewald tolerance
    real(dp) :: tolEwald = 1.0E-9_dp

    !> Various options
    logical :: tWriteTagged = .false.

    !> Nr. of SCC iterations without restart info
    integer :: restartFreq  = 20
    logical :: tWriteDetailedXML = .false.
    logical :: tWriteResultsTag = .false.
    logical :: tWriteDetailedOut = .true.
    logical :: tWriteBandDat = .true.
    logical :: oldSKInter = .false.
    logical :: tWriteHS = .false.
    logical :: tWriteRealHS = .false.
    logical :: tMinMemory = .false.

    !> Potential shifts are read from file
    logical :: tReadShifts = .false.
    !> Potential shifts are written on file
    logical :: tWriteShifts = .false.

    !> Use Poisson solver for electrostatics
    logical :: tPoisson = .false.

    !> Dispersion related stuff
    type(TDispersionInp), allocatable :: dispInp

    !> Solvation
    class(TSolvationInp), allocatable :: solvInp

    !> Electronic constraints
    type(TElecConstraintInp), allocatable :: elecConstraintInp

    !> Rescaling of electric fields (applied or dipole) if the system is solvated
    logical :: isSolvatedFieldRescaled = .false.

    !> Input for tblite library
    type(TTBLiteInput), allocatable :: tbliteInp

    !> Local potentials
    real(dp), allocatable :: chrgPenalty(:,:)
    real(dp), allocatable :: thirdOrderOn(:,:)


    !> 3rd order
    real(dp), allocatable :: hubDerivs(:,:)
    logical :: t3rd = .false.
    logical :: t3rdFull = .false.


    !> XLBOMD
    type(TXLBOMDInp), allocatable :: xlbomd

    !> TD Linear response input
    type(TLinrespini), allocatable :: lrespini

    !> ElectronDynamics
    type(TElecDynamicsInp), allocatable :: elecDynInp

    !> Input for particle-particle RPA
    type(TppRPAcal), allocatable :: ppRPA

    !> LBFGS input
    type(TLbfgsInput), allocatable :: lbfgsInp

    !> Geometry optimizer input
    type(TGeoOptInput), allocatable :: geoOpt

    !> Hybrid xc-functional input
    type(THybridXcInp), allocatable :: hybridXcInp

    !> Multipole expansion
    logical :: isMdftb = .false.
    type(TMdftbAtomicIntegrals), allocatable :: mdftbAtomicIntegrals

  #:if WITH_SOCKETS
    !> Socket communication
    type(ipiSocketCommInp), allocatable :: socketInput
  #:endif

    type(TParallelOpts), allocatable :: parallelOpts

    !> Maximal timing level to show in output
    integer :: timingLevel

    !> Array of lists of atoms where the 'neutral' shell occupation is modified
    type(TWrappedInt1), allocatable :: customOccAtoms(:)

    !> Modified occupations for shells of the groups atoms in customOccAtoms
    real(dp), allocatable :: customOccFillings(:,:)

    ! TI-DFTB variables

    !> Non-Aufbau filling
    logical :: isNonAufbau = .false.

    !> SpinPurify
    logical :: isSpinPurify = .false.

    !> GroundGuess
    logical :: isGroundGuess = .false.

    !> REKS input
    type(TReksInp) :: reksInp

    !> Whether Scc should be updated with the output charges (obtained after diagonalization)
    !> Could be set to .false. to prevent costly recalculations (e.g. when using Poisson-solver)
    logical :: updateSccAfterDiag = .true.

    !> Write cavity information as COSMO file
    logical :: tWriteCosmoFile = .false.

    !> Whether ChIMES correction for repulsives should be applied.
    type(TChimesRepInp), allocatable :: chimesRepInput

    !> File access type to use when opening binary files for reading and writing
    character(20) :: binaryAccessTypes(2)

  end type TControl


  !> Slater-Koster data
  type TSlater
    real(dp), allocatable :: skSelf(:, :)
    real(dp), allocatable :: skHubbU(:, :)
    real(dp), allocatable :: skOcc(:, :)
    real(dp), allocatable :: mass(:)

    type(TSlakoCont), allocatable :: skHamCont
    type(TSlakoCont), allocatable :: skOverCont
    type(TOrbitals), allocatable :: orb
    type(TPairRepulsiveItem), allocatable :: pairRepulsives(:,:)

  end type TSlater

#:if WITH_TRANSPORT

  !> Container for data needed by libNEGF
  type TNEGFInfo
    !> Transport section informations
    type(TNEGFTunDos) :: tundos
    !> NEGF solver section informations
    type(TNEGFGreenDensInfo) :: greendens
  end type TNEGFInfo

#:else

  !> Dummy type replacement
  type TNegfInfo
  end type TNegfInfo

#:endif


  !> Container for input data constituents
  type TInputData
    logical :: tInitialized = .false.
    type(TControl) :: ctrl
    type(TGeometry) :: geom
    type(TSlater) :: slako
  #:if WITH_TRANSPORT
    type(TTransPar) :: transpar
    type(TNEGFInfo) :: ginfo
  #:endif
    type(TPoissonInfo) :: poisson
  end type TInputData


  !> Initialise the input data
  interface init
    module procedure InputData_init
  end interface init


  !> Destroy input data for variables that do not go out of scope
  interface destruct
    module procedure InputData_destruct
  end interface destruct

contains


  !> Mark data structure as initialised
  subroutine InputData_init(this)

    !> Instance
    type(TInputData), intent(out) :: this

    this%tInitialized = .true.

  end subroutine InputData_init


  !> Destructor for parts that are not cleaned up when going out of scope
  subroutine InputData_destruct(this)

    !> Instance
    type(TInputData), intent(inout) :: this

    call Control_destruct(this%ctrl)

  end subroutine InputData_destruct


  !> Destructor for parts that are not cleaned up when going out of scope
  subroutine Control_destruct(this)

    !> Instance
    type(TControl), intent(inout) :: this

    if (allocated(this%tShellResInRegion)) then
      call destruct(this%iAtInRegion)
    end if

  end subroutine Control_destruct

end module dftbp_dftbplus_inputdata
