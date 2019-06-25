pragma solidity ^0.5.2;
//pragma experimental ABIEncoderV2;
import "./sistemamedicointerface.sol";

contract CentroMedico {
    event LogRecordWrite(address triggerId, address impactedId, uint dateTime);
    mapping (address => ProfessionalInMedicalCenter[]) professionalByMedicalCenter;
    uint professionalByMedicalCenterCount;
    
    SistemaMedicoInteface sMI;

    function setSistemaMedicoAddress(address _address) external{
        sMI = SistemaMedicoInteface(_address);
    }
    
    //Restringe el uso por parte de un manager
    modifier onlyManager() {
        require(sMI.isAdmin(msg.sender), "No es manager del sistema");
        _;
    }
    
    //Restringe el uso por parte del centro médico
    modifier onlyMedicalCenter() {
        require(sMI.isMedicalCenter(msg.sender), "No es un Centro Médico del sistema");
        _;
    }
    
    struct ProfessionalInMedicalCenter {
        address professionalId;
        bool active;
    }
    
    //*********************      
    //*********************  
    
    function isProfessionalInMedicalCenter(address _address) public view returns(bool isProfByMedCenter) {
        ProfessionalInMedicalCenter[] memory ProfessionalInMedicalCenterAux = professionalByMedicalCenter[msg.sender];
        for(uint i=0; i < ProfessionalInMedicalCenterAux.length; i++) {
            if (ProfessionalInMedicalCenterAux[i].professionalId == _address) {
                return true;       
            }
        }
    }
    
    function setProfessionalInMedicalCenter(address _address) public onlyMedicalCenter() {
        ProfessionalInMedicalCenter memory doctorInformation;
        require(!isProfessionalInMedicalCenter(_address) &&  _address != address(0), "Profesional ya existe en el Centro Médico");
        require(sMI.isProfessional(_address), "El médico ingresado no es reconocido por sistema médico");
        doctorInformation.professionalId = _address;
        doctorInformation.active = true;
        professionalByMedicalCenter[msg.sender].push(doctorInformation);
        emit LogRecordWrite(msg.sender, _address, now);
    }
    
    function getIdProfessionalInMedicalCenter(address _address) private view onlyMedicalCenter() returns(uint id){
        ProfessionalInMedicalCenter[] memory ProfessionalInMedicalCenterAux = professionalByMedicalCenter[msg.sender];
        for(uint i=0; i < ProfessionalInMedicalCenterAux.length; i++) {
            if (ProfessionalInMedicalCenterAux[i].professionalId == _address) {
               return i;
            }
        }      
    }
    
    function removeProfessionalInMedicalCenter(address _address) public onlyMedicalCenter() {
        require(isProfessionalInMedicalCenter(_address) && _address != address(0), "Profesional no existe en el Centro Médico");
        removeArrayPMC(getIdProfessionalInMedicalCenter(_address));    
        emit LogRecordWrite(msg.sender, _address, now);
    }
    
    function removeArrayPMC(uint index) private {
        ProfessionalInMedicalCenter[] storage  ProfessionalInMedicalCenterAux = professionalByMedicalCenter[msg.sender];
        if (index >= ProfessionalInMedicalCenterAux.length) return;

        for (uint i = index; i<ProfessionalInMedicalCenterAux.length-1; i++){
            ProfessionalInMedicalCenterAux[i] = ProfessionalInMedicalCenterAux[i+1];
        }
        delete ProfessionalInMedicalCenterAux[ProfessionalInMedicalCenterAux.length-1];
        ProfessionalInMedicalCenterAux.length--;
        professionalByMedicalCenter[msg.sender] = ProfessionalInMedicalCenterAux;
    }
    
    function setLeave(address _address) public onlyMedicalCenter() {
        require(isProfessionalInMedicalCenter(_address) && _address != address(0), "Profesional no existe en el Centro Médico");
        professionalByMedicalCenter[msg.sender][getIdProfessionalInMedicalCenter(_address)].active = false;
        emit LogRecordWrite(msg.sender, _address, now);
    }    
    
    function getProfessionalByMedicalCenterCount() public view onlyMedicalCenter() onlyManager() returns(uint quantity) {
        return professionalByMedicalCenter[msg.sender].length;
    }
    

}