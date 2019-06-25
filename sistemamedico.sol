pragma solidity ^0.5.2;

import "github.com/OpenZeppelin/zeppelin-solidity/contracts/ownership/Ownable.sol";

contract SistemaMedico is Ownable{
    event LogRecordWrite(address triggerId, address impactedId, uint dateTime);

    string[] speciality; // Listado completo y validado de especialidades por el sistema medico
    mapping (address => bool) private admins; // Operadores Autorizados del sistema medico
    mapping (address => Profesional) private professional;
    mapping (address => bool) private medicalCenter;
    
    uint adminCount=0;
    uint professionalCount=0;
    uint centerCount=0;
    
    struct Profesional {
        bool active;
        uint[] idSpeciality; //se asocian especialidades al medico para su clasificación
    }
    
    //Restringe el uso por parte de un manager
    modifier onlyManager() {
        require(isAdmin(msg.sender), "No es manager del sistema");
        _;
    }
    
    //Restringe el uso por parte del centro médico
    modifier onlyMedicalCenter() {
        require(isMedicalCenter(msg.sender), "No es un Centro Médico del sistema");
        _;
    }
    //*********************
    function isAdmin(address _address) public view returns(bool isAdm) {
        return admins[_address];
    }
    
    function setAdmin(address _address) public onlyOwner() {
        require(!isAdmin(_address) && _address != address(0), "Administrador ya existe");
        admins[_address] = true;
        adminCount++;
        emit LogRecordWrite(msg.sender, _address, now);
    }
    
    function removeAdmin(address _address) public onlyOwner() {
        require(isAdmin(_address) && _address != address(0), "Administrador no existe");
        admins[_address] = false;
        delete admins[_address];
        adminCount--;
        emit LogRecordWrite(msg.sender, _address, now);
    }
    
    function getAdminCount() public view onlyManager() onlyOwner() returns(uint quantity) {
        return adminCount;
    }
    
    //*********************      
    //*********************  
    
    function isProfessional(address _address) public view returns(bool isProf) {
        return professional[_address].active;
    }
    
    //Cambiar para que lo gestione el admin
    function setProfessional(address _address, uint[] memory _specialities) public onlyManager() {
        require(!isProfessional(_address) && _address != address(0), "Profesional ya existe");
        require(!isAdmin(_address), "No puede ingresar a un administrador como Medico");
        require(!isMedicalCenter(_address), "No puede ingresar a un centro  medico como Medico");
        professional[_address].active = true;
        professional[_address].idSpeciality = _specialities;
        professionalCount++;
        emit LogRecordWrite(msg.sender, _address, now);
    }
    
    function removeProfessional(address _address) public onlyManager() {
        require(isProfessional(_address) && _address != address(0), "Profesional no existe");
        professional[_address].active = false;
        delete professional[_address].idSpeciality;
        delete professional[_address];
        professionalCount--;
        emit LogRecordWrite(msg.sender, _address, now);
    }
    
    function getProfessionalCount() public view onlyManager() returns(uint quantity) {
        return professionalCount;
    }
    
    function getProfessionalSpecialities(address _address) public view onlyManager() returns (uint[] memory specialities){
        return professional[_address].idSpeciality;
    }
    
    //*********************      
    //*********************  
    
    // gestiona la creacion de Especialidades Medicas (solo puede hacerlo un manager)
    function setMedicalSpeciality(string memory _name) public onlyManager() {
        speciality.push(_name);
    }
    
    function getIdMedicalSpeciality(string memory _name) public view onlyManager returns (uint resultado) {
        for (uint i=0;speciality.length-1>=i;i++){
            if (keccak256(abi.encodePacked((_name))) == keccak256(abi.encodePacked((speciality[i])))) {
                return i;
            }
        }
    }
    
    //*********************      
    //*********************  
    
    // gestiona la creación de Centros Médicos
    function isMedicalCenter(address _address) public view returns(bool isMedCenter) {
        return medicalCenter[_address];
    }
    
    function setMedicalCenter(address _address) public onlyManager() {
        require(!isMedicalCenter(_address) && _address != address(0), "Centro Médico ya existe");
        require(!isProfessional(_address), "No puede ingresar un medico como centro medico");
        require(!isAdmin(_address), "No puede ingresar un administrador como centro medico");
        medicalCenter[_address] = true;
        centerCount++;
        emit LogRecordWrite(msg.sender, _address, now);
    }
    
    function removeMedicalCenter(address _address) public onlyManager() {
        require(isMedicalCenter(_address) && _address != address(0), "Centro Médico  no existe");
        medicalCenter[_address] = false;
        delete medicalCenter[_address];
        centerCount--;
        emit LogRecordWrite(msg.sender, _address, now);
    }
    function getMedicalCenterCount() public view onlyManager() returns(uint quantity) {
        return centerCount;
    }

    //*********************      
    //*********************  
}