pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

import "./centromedicointerface.sol";
import "./sistemamedicointerface.sol";

contract PacienteHC {
    event LogRecordWrite(address triggerId, address impactedId, uint dateTime);
    CentroMedicoInterface cMI;
    SistemaMedicoInteface sMI;
    uint patientCount=0;
    
    mapping (address => Paciente) private paciente;
    Diagnosys diagnosys;

    struct Paciente {
        uint status; //vivos, muerto o desaparecido 1-2-3
        Diagnosys[] diagnosys;
    }
    
    struct Diagnosys {
        uint todayDateTime;
        string symtom;
        string treatment;
        uint durationInDays;
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
    
    function setSistemaMedicoAddress(address _address) external{
        sMI = SistemaMedicoInteface(_address);
    }
    
    function setCentroMedicoAddress(address _address) external{
        cMI = CentroMedicoInterface(_address);
    }
    
    function isStatus(address _address) private view returns(uint status) {
        return paciente[_address].status;
    }
    
    function setDiagnosys(address _address, string memory _symtom, string memory _treatment, uint _durationInDays) public checkManager() checkMedicalCenter() checkDoctor()   {
        require((_address != msg.sender) , "Un Médico no puede diagnosticarse a si mismo");
        require((paciente[_address].status != 2), "El paciente figura 'fallecido' no se pueden registrar nuevos diagnosticos");
        if (paciente[_address].status == 0) {
            require ((keccak256(abi.encodePacked((_symtom))) == keccak256(abi.encodePacked(("vivo")))),"El primer diagnostico de un paciente debe ser 'vivo'"); 
            setNewPatient( _address,  _symtom,  _treatment,  _durationInDays);
        }
        else
        {
            require ((paciente[_address].status == 1), "Debe cambiar el estado del paciente para poder cargar un nuevo diagnostico");
            loadDiagnosys(_address,  _symtom,  _treatment,  _durationInDays);
        }
    }
    
    function setNewPatient(address _address, string memory _symtom, string memory _treatment, uint _durationInDays) private checkManager() checkMedicalCenter() checkDoctor() {
        //se agrega un nuevo paciente
        //se carga el diagnostico
        paciente[_address].status = 1;
        patientCount++;
        loadDiagnosys(_address,  _symtom,  _treatment,  _durationInDays);
    }
    
    function removePatient(address _address, string memory _symtom, string memory _treatment, uint _durationInDays) public checkManager() checkMedicalCenter() checkDoctor() {
        //se carga el diagnostico y se cambia el estado a muerto
        paciente[_address].status = 2;
        patientCount--;
        loadDiagnosys(_address,  _symtom,  _treatment,  _durationInDays);
    }
    
    function updatePatientStatus(address _address, uint _status) public checkManager() checkMedicalCenter() checkDoctor() {
        require ((paciente[_address].status == 1) || (paciente[_address].status == 3), "Solo puede modificarse el estado 'vivo' o 'desaparecido'");
        paciente[_address].status = _status;
        emit LogRecordWrite(msg.sender, _address, now);
    }
    
    function loadDiagnosys(address _address, string memory _symtom, string memory _treatment, uint _durationInDays) private {
        diagnosys.todayDateTime = now;
        diagnosys.symtom = _symtom;
        diagnosys.treatment =_treatment;
        diagnosys.durationInDays = _durationInDays;
        paciente[_address].diagnosys.push(diagnosys);
        emit LogRecordWrite(msg.sender, _address, now);
    }
    
    function getDiagnosys(address _address) public view checkDoctor() returns (Diagnosys[] memory diagnosysResultado) {
        return paciente[_address].diagnosys;
    }
    
    
}
