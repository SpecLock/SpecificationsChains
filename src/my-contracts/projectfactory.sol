/**
 * @title Project Contract
 * @dev Manages a project with milestones. The owner of the project can add milestones and approve completed milestones,
 *      while the designated developer can mark milestones as completed.
 *
 * State Variables:
 * - owner: The creator and owner of the project.
 * - projectName: The name of the project.
 * - projectDescription: A brief description of the project.
 * - developerAddress: The address of the developer responsible for executing milestones.
 * - totalCapital: The initial capital provided for the project, decreasing as milestones are added.
 * - milestones: An array storing all the milestones related to the project.
 *
 * Structs:
 * - Milestone: Represents a project milestone with a title, tentative date, description, payment amount, and completion status.
 *
 * Modifiers:
 * - onlyOwner: Restricts function execution to the project owner.
 *
 * Events:
 * - MilestoneAdded: Triggered when a new milestone is added. Contains the milestone's ID, title, and allocated amount.
 * - MilestoneCompleted: Triggered when a milestone is marked as completed by the developer. Contains the milestone's ID and proof.
 * - MilestoneApproved: Triggered when a milestone is approved and funds are released. Contains the milestone's ID and the payment amount.
 *
 * Functions:
 * - constructor: Initializes the project with the owner, name, description, developer address, and total capital (ensures msg.value matches the total capital).
 * - addMilestone: Allows the owner to add a new milestone. Verifies the milestone's amount does not exceed the remaining capital,
 *                 deducts the amount from totalCapital, and emits the MilestoneAdded event.
 * - completeMilestone: Allows the developer to mark a milestone as completed. Checks that the milestone has not been completed before and emits the MilestoneCompleted event.
 * - approveMilestone: Allows the owner to approve a completed milestone. It transfers the allocated funds to the developer if the milestone is completed and not already paid,
 *                     resets the milestone's amount to 0, and emits the MilestoneApproved event.
 * - getMilestonesCount: Returns the total number of milestones added to the project.
 */

/**
 * @title ProjectFactory Contract
 * @dev Responsible for the creation and tracking of multiple Project contracts.
 *
 * State Variables:
 * - projects: An array that stores all deployed Project contract instances.
 *
 * Events:
 * - ProjectCreated: Triggered when a new Project contract is deployed. Contains the new project's address and the owner's address.
 *
 * Functions:
 * - createProject: Deploys a new Project contract with the specified project name, description, developer address, and total capital.
 *                  The msg.value sent must match the total capital required for the project.
 *                  Adds the new project to the projects array and emits the ProjectCreated event.
 * - getProjects: Returns a view of the array containing all deployed Project contract instances.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Project {
    struct Milestone {
        string title;
        uint256 tentativeDate;
        string description;
        uint256 amount;
        bool completed;
    }

    address public owner;
    string public projectName;
    string public projectDescription;
    address payable public developerAddress;
    uint256 public totalCapital;
    Milestone[] public milestones;

    event MilestoneAdded(uint256 indexed milestoneId, string title, uint256 amount);
    event MilestoneCompleted(uint256 indexed milestoneId, string proof);
    event MilestoneApproved(uint256 indexed milestoneId, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el owner puede ejecutar esta funcion");
        _;
    }

    constructor(
        address _owner,
        string memory _projectName,
        string memory _projectDescription,
        address payable _developerAddress,
        uint256 _totalCapital
    ) payable {
        require(msg.value == _totalCapital, "El valor enviado debe coincidir con el capital total");
        owner = _owner;
        projectName = _projectName;
        projectDescription = _projectDescription;
        developerAddress = _developerAddress;
        totalCapital = _totalCapital;
    }

    function addMilestone(string memory _title, uint256 _tentativeDate, string memory _description, uint256 _amount)
        external
        onlyOwner
    {
        require(_amount <= totalCapital, "Monto excede el capital restante");
        milestones.push(
            Milestone({
                title: _title,
                tentativeDate: _tentativeDate,
                description: _description,
                amount: _amount,
                completed: false
            })
        );
        totalCapital -= _amount;
        emit MilestoneAdded(milestones.length - 1, _title, _amount);
    }

    function completeMilestone(uint256 _milestoneId, string memory _proof) external {
        require(msg.sender == developerAddress, "Solo el desarrollador puede completar hitos");
        Milestone storage milestone = milestones[_milestoneId];
        require(!milestone.completed, "Hito ya completado");
        milestone.completed = true;
        emit MilestoneCompleted(_milestoneId, _proof);
    }

    function approveMilestone(uint256 _milestoneId) external onlyOwner {
        Milestone storage milestone = milestones[_milestoneId];
        require(milestone.completed, "Hito no completado");
        require(milestone.amount > 0, "Hito ya pagado");
        uint256 amount = milestone.amount;
        milestone.amount = 0;
        developerAddress.transfer(amount);
        emit MilestoneApproved(_milestoneId, amount);
    }

    function getMilestonesCount() external view returns (uint256) {
        return milestones.length;
    }
}

contract ProjectFactory {
    Project[] public projects;

    event ProjectCreated(address indexed projectAddress, address indexed owner);

    function createProject(
        string memory _name,
        string memory _description,
        address payable _developerAddress,
        uint256 _totalCapital
    ) external payable returns (address projectAddress) {
        Project newProject =
            new Project{value: msg.value}(msg.sender, _name, _description, _developerAddress, _totalCapital);
        projects.push(newProject);
        emit ProjectCreated(address(newProject), msg.sender);
        return address(newProject);
    }

    function getProjects() external view returns (Project[] memory) {
        return projects;
    }
}
