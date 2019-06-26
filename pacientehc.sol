pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "./centromedicointerface.sol";
import "./sistemamedicointerface.sol";
/*
Este contrato permite gestionar la historia clinica del "paciente" quien se identifica en todo momento con su address 
Dicho paciente dispone una estructura simple con posibilidad de extender sus propiedades.
Se disponen de 2 interfaces una a Sistema Central y otra a Centro Medico
*/
contract PacienteHC {
    event LogRecordWrite(address triggerId, address impactedId, uint dateTime);
    CentroMedicoInterface cMI;
    SistemaMedicoInteface sMI;
    uint patientCount=0; //contamos solo pacientes vivos o desaparecidos los muertos disminuyen el contador
    
    mapping (address => Paciente) private paciente; //contiene a los pacientes
    Diagnosys diagnosys; //contiene la estructura del diagnostico

    struct Paciente {
        uint status; //vivos, muerto o desaparecido 1-2-3
        Diagnosys[] diagnosys; //array con diagnosticos del paciente
    }
    
    struct Diagnosys {
        uint todayDateTime;
        string symtom;
        string treatment;
        uint durationInDays;
        address medicalCenter; //Se deja constancia del Centro Medico al que pertence en ese momento el medico que atendio
    }
    
    //Restringe el uso por parte de un manager
    modifier checkManager() {
        require(!sMI.isAdmin(msg.sender), "Un manager no puede actualizar una HC");
        _;
    }
    
    //Restringe el uso por parte del centro médico
    modifier checkMedicalCenter() {
        require(!sMI.isMedicalCenter(msg.sender), "Un Centro Medico no puede actualizar una HC");
        _;
    }

    //Restringe al medico a no diagnosticarse a si mismo
    modifier checkDoctor() {
        require(sMI.isProfessional(msg.sender), "Solo un Medico puede actualizar la HC");
        _;
    }
    
    //Se inicializa la variable de Sistema Medico recibiendo la direccion el la cadena
    function setSistemaMedicoAddress(address _address) external{
        sMI = SistemaMedicoInteface(_address);
    }
    
    //Se inicializa la variable de Centro Medico recibiendo la direccion el la cadena
    function setCentroMedicoAddress(address _address) external{
        cMI = CentroMedicoInterface(_address);
    }
    
    //devuelve el estado del paciente (vivo, muerto, ddesaparecido)
    function isStatus(address _address) private view returns(uint status) {
        return paciente[_address].status;
    }
    
    /*permite definir un diagnostico para un paciente si y solo si 
        quien defina el diagnostico sea un medico, que no se este diagnosticando a si mismo,
        que pertenezca a un centro medico, que en el centro medico se encuentre activo, que el paciente no este 'muerto'
        En caso que el estado del paciente es 0 (que no tiene estado) se lo crea en el sistema si y solo si el diagnostico provisto
        por el medico es 'vivo' obteniendo su primer diagnostico.
        En caso que el estado del paciente no sea 0 el sistema valida si su estado es 1 = 'vivo' sino lo es su estado es 'desaparecido=3'
        en ese caso se pide cambiar su estado  antes de agregar un nuevo diagnostico. 
        
    */
    function setDiagnosys(address _address, string memory _symtom, string memory _treatment, uint _durationInDays, address _medicalCenter) public checkDoctor()   {
        require((_address != msg.sender) , "Un Médico no puede diagnosticarse a si mismo");
        require((sMI.isMedicalCenterInProfessional(_medicalCenter, _address)) , "El Médico no pertenece al Centro Medico indicado");
        require((cMI.isProfessionalInMedicalCenterActive(_medicalCenter, _address)) , "El Médico no se encuentra activo en el Centro Medico indicado");
        require((paciente[_address].status != 2), "El paciente figura 'muerto' no se pueden registrar nuevos diagnosticos");
        if (paciente[_address].status == 0) {
            require ((keccak256(abi.encodePacked((_symtom))) == keccak256(abi.encodePacked(("vivo")))),"El primer diagnostico de un paciente debe ser 'vivo'"); 
            setNewPatient( _address,  _symtom,  _treatment,  _durationInDays, _medicalCenter);
        }
        else
        {
            require ((paciente[_address].status == 1), "Debe cambiar el estado del paciente para poder cargar un nuevo diagnostico");
            addDiagnosys(_address,  _symtom,  _treatment,  _durationInDays, _medicalCenter);
        }
    }
    
    /*Se encarga de agregar un nuevo paciente, asignando el estado=1 'vivo'
    incrementamos la cantidad de pacientes que gestiona el sistema y
    agregamos el primer diagnostico
    */
    function setNewPatient(address _address, string memory _symtom, string memory _treatment, uint _durationInDays, address _medicalCenter) private checkDoctor() {
        //se agrega un nuevo paciente
        //se carga el diagnostico
        paciente[_address].status = 1;
        patientCount++;
        addDiagnosys(_address,  _symtom,  _treatment,  _durationInDays, _medicalCenter);
    }
    
    /*
        Cambia el estado del paciente 'muerto'=2 se reduce la cantidad de pacientes 
    
    */
    function removePatient(address _address, string memory _symtom, string memory _treatment, uint _durationInDays, address _medicalCenter) public checkDoctor() {
        //se carga el diagnostico y se cambia el estado a muerto 
        require((_address != msg.sender) , "Un Médico no puede diagnosticarse a si mismo");
        require((sMI.isMedicalCenterInProfessional(_medicalCenter, _address)) , "El Médico no pertenece al Centro Medico indicado");
        require((cMI.isProfessionalInMedicalCenterActive(_medicalCenter, _address)) , "El Médico no se encuentra activo en el Centro Medico indicado");
        paciente[_address].status = 2;
        patientCount--;
        addDiagnosys(_address,  _symtom,  _treatment,  _durationInDays, _medicalCenter);
    }
    
    /*
        Se utiliza la funcion updatePatientStatus
        pudiendose cambiar el estado de 1 a 2 o de 3 a 1
    */
    function updatePatientStatus(address _address, uint _status) public checkManager() checkMedicalCenter() checkDoctor() {
        require ((paciente[_address].status == 1) || (paciente[_address].status == 3), "Solo puede modificarse el estado 'vivo' o 'desaparecido'");
        paciente[_address].status = _status;
        emit LogRecordWrite(msg.sender, _address, now);
    }
    
    //Agregamos el diagnostico al paciente
    function addDiagnosys(address _address, string memory _symtom, string memory _treatment, uint _durationInDays, address _medicalCenter) private {
        diagnosys.todayDateTime = now;
        diagnosys.symtom = _symtom;
        diagnosys.treatment =_treatment;
        diagnosys.durationInDays = _durationInDays;
        diagnosys.medicalCenter =_medicalCenter;
        paciente[_address].diagnosys.push(diagnosys);
        emit LogRecordWrite(msg.sender, _address, now);
    }
    //Obtenemos todos los diagnosticos contenidos en el array dentro de paciente
    function getDiagnosys(address _address) public view checkDoctor() returns (Diagnosys[] memory diagnosysResultado) {
        return paciente[_address].diagnosys;
    }
    
    
}
