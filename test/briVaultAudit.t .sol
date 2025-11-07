// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {BriVault} from "../src/briVault.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {MockERC20} from "./MockErc20.t.sol";
import {BriTechToken} from "../src/briTechToken.sol";


contract BriVaultAuditTest is Test {
    uint256 public participationFeeBsp;
    uint256 public eventStartDate;
    uint256 public eventEndDate;
    address public participationFeeAddress;
    uint256 public minimumAmount;

    // Vault contract
    BriVault public briVault;
    MockERC20 public mockToken;
    BriTechToken public briTechToken;

    // Users
    address attacker = makeAddr("attacker");
    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address user4 = makeAddr("user4");
    address user5 = makeAddr("user5");

    string[48] countries = [
        "United States", "Canada", "Mexico", "Argentina", "Brazil", "Ecuador",
        "Uruguay", "Colombia", "Peru", "Chile", "Japan", "South Korea",
        "Australia", "Iran", "Saudi Arabia", "Qatar", "Uzbekistan", "Jordan",
        "France", "Germany", "Spain", "Portugal", "England", "Netherlands",
        "Italy", "Croatia", "Belgium", "Switzerland", "Denmark", "Poland",
        "Serbia", "Sweden", "Austria", "Morocco", "Senegal", "Nigeria",
        "Cameroon", "Egypt", "South Africa", "Ghana", "Algeria", "Tunisia",
        "Ivory Coast", "New Zealand", "Costa Rica", "Panama", "United Arab Emirates", "Iraq"
    ];

    function setUp() public {
        participationFeeBsp = 150; // 1.5%
        eventStartDate = block.timestamp + 2 days;
        eventEndDate = eventStartDate + 31 days;
        participationFeeAddress = makeAddr("participationFeeAddress");
        minimumAmount = 0.0002 ether;

        mockToken = new MockERC20("Mock Token", "MTK");

        mockToken.mint(owner, 20 ether);
        mockToken.mint(attacker, 20 ether);
        mockToken.mint(user1, 20 ether);
        mockToken.mint(user2, 20 ether);
        mockToken.mint(user3, 20 ether);
        mockToken.mint(user4, 20 ether);
        mockToken.mint(user5, 20 ether);

        vm.startPrank(owner);
        briVault = new BriVault(
            IERC20(address(mockToken)), // replace `address(0)` with actual _asset address
            participationFeeBsp,
            eventStartDate,
            participationFeeAddress,
            minimumAmount,
            eventEndDate
        );

        briVault.approve(address(mockToken), type(uint256).max);
                
        briVault.setCountry(countries);

          vm.stopPrank();
    }

//---------------SENT-----------------------
    function testDOSAttackOnUsersAddressArray() public {
        uint256 depositAmount = 1 ether;
        vm.startPrank(attacker);
        mockToken.approve(address(briVault), depositAmount);
        briVault.deposit(depositAmount, attacker);
        vm.stopPrank();
        for(uint256 i = 0; i < 35000; i++) {
            vm.prank(attacker);
            briVault.joinEvent(0);
        }

        vm.warp(briVault.eventEndDate() +1);
        
        vm.startPrank(owner);
        uint256 gasLimit = 30_000_000;
        uint256 gasBefore = gasleft();
        briVault.setWinner(0); 
        uint256 gasUsed = gasBefore - gasleft();
        
        vm.stopPrank();
        assertGt(gasLimit, gasUsed, "OutOfGas");

    }

    function testUserCanJoinEventMultipleTimesJoiningEveryCountryId() public {
        //l' user può joinare più volte l'evento scegliendo ogni volta un countryId differente
        //assicurandosi sempre la vittoria
        uint256 victimDepositAmount = 1 ether;
        uint256 expectedVictimShares = briVault.convertToShares(victimDepositAmount) * 
            (10000 - participationFeeBsp) / 10000;
        vm.startPrank(user2);
        mockToken.approve(address(briVault), victimDepositAmount);
        briVault.deposit(victimDepositAmount, user2);
        briVault.joinEvent(2); 
        vm.stopPrank();

        vm.startPrank(user4);
        mockToken.approve(address(briVault), victimDepositAmount);
        briVault.deposit(victimDepositAmount, user4);
        briVault.joinEvent(4); 
        vm.stopPrank();

        vm.startPrank(user3);
        mockToken.approve(address(briVault), victimDepositAmount);
        briVault.deposit(victimDepositAmount, user3);
        briVault.joinEvent(3); 
        vm.stopPrank();
        
        vm.startPrank(user5);
        mockToken.approve(address(briVault), victimDepositAmount);
        briVault.deposit(victimDepositAmount, user5);
        briVault.joinEvent(47); 
        vm.stopPrank();

        uint256 winnerInitBalance = mockToken.balanceOf(user1);
        uint256 depositAmount = mockToken.balanceOf(user1); //20eth
        uint256 expectedShares = briVault.convertToShares(depositAmount) * (10000 - participationFeeBsp) / 10000;
        vm.startPrank(user1);
        mockToken.approve(address(briVault), depositAmount);
        briVault.deposit(depositAmount, user1);   
        for(uint256 i = 0; i < 48 ; i++) {
            briVault.joinEvent(i); // joining with every countryId
        }
        vm.stopPrank();
        // user1 should have shares for every countryId joined
        for(uint256 i = 0; i < 48; i++) {
            uint256 shares = briVault.userSharesToCountry(user1, i);
            assertEq(shares, expectedShares);
        }

        uint256 expectedTotalShares = (expectedVictimShares * 4) + expectedShares;
        assertEq(expectedTotalShares, briVault.totalSupply());

        vm.warp(briVault.eventEndDate() + 1);

        vm.prank(owner);
        briVault.setWinner(47);
        uint256 finalizedVaultAsset = mockToken.balanceOf(address(briVault));
        vm.prank(user1);
        briVault.withdraw();
        uint256 winnerFinalBalance = mockToken.balanceOf(user1);
        uint256 expectedWin = (expectedShares * finalizedVaultAsset) / expectedShares;
        assertEq(expectedWin, winnerFinalBalance - winnerInitBalance);
    }

    function testDepositSendSharesToWrongAddress() public {
        uint256 depositAmount = 1 ether;
        uint256 expectedShares = briVault.convertToShares(depositAmount) * (10000 - participationFeeBsp) / 10000;
        vm.startPrank(user1);
        mockToken.approve(address(briVault), depositAmount);
        briVault.deposit(depositAmount, user2);   
        vm.stopPrank();
        // stakedAssetMapping should reflect user's shares amount
        assertEq(briVault.balanceOf(user1), expectedShares); // user1 shares
        assertEq(briVault.stakedAsset(user1), 0); // user1 mapping
        
        assertEq(briVault.balanceOf(user2), 0); // user2 shares 
        assertEq(briVault.stakedAsset(user2), expectedShares ); // user2 mapping
       

        //User2 with no shares can join event
        vm.startPrank(user2);
        briVault.joinEvent(0); // joining with countryId 0
        vm.stopPrank();

    }

    function testOwnerCanPartecipateAndSetHisTeamAsWinner() public {
        //owner can both partecipate and choose the winner
        uint256 depositAmount = 5 ether;
        vm.startPrank(user1);
        mockToken.approve(address(briVault), depositAmount);
        briVault.deposit(depositAmount, user1);   
        briVault.joinEvent(2); // joining with countryId 2
        vm.stopPrank();

        vm.startPrank(user2);
        mockToken.approve(address(briVault), depositAmount);
        briVault.deposit(depositAmount, user2);   
        briVault.joinEvent(3); // joining with countryId 3
        vm.stopPrank();

        vm.startPrank(owner);
        uint256 ownerBalanceBeforeDeposit = mockToken.balanceOf(owner);
        mockToken.approve(address(briVault), ownerBalanceBeforeDeposit);
        briVault.deposit(ownerBalanceBeforeDeposit, owner);   
        briVault.joinEvent(1); // joining with countryId 1
        vm.warp(briVault.eventEndDate() +1);
        briVault.setWinner(1); // setting winner to countryId 1
        vm.stopPrank();
        
        // total vault assets
        uint256 totalVaultAsset = mockToken.balanceOf(address(briVault));
        console.log("vault token balance: ", totalVaultAsset);

        //owner withdraw
        vm.prank(owner);
        briVault.withdraw();
        console.log("vault token balance after withdraw: ", mockToken.balanceOf(address(briVault)));

        uint256 ownerFinalBalance = mockToken.balanceOf(owner);
        console.log("owner final balance: ", ownerFinalBalance);
        // owner should receive all vault assets
        // owner deposited full balance so initial balance is 0
        assertEq(ownerFinalBalance, totalVaultAsset); 
    }

    function testOwnerCanSetCountryAfterUsersStartedEnteringTheGame() public {
        uint256 depositAmount = 5 ether;
        uint256 countryIdToJoin = 2;
        string memory countryName = briVault.teams(countryIdToJoin); //on setup is "Mexico"
        vm.startPrank(user1);
        mockToken.approve(address(briVault), depositAmount);
        briVault.deposit(depositAmount, user1);   
        briVault.joinEvent(countryIdToJoin); // joining with countryId 2
        vm.stopPrank();
        assertEq(briVault.userToCountry(user1), countryName);

        //new array of countries with new country on each array slot
        string[48] memory newCountries = [
        "Canada", "Mexico", "Argentina", "Brazil", "Ecuador", "Uruguay", "Colombia", "Peru", "Chile", "Japan", "South Korea",
        "Australia", "Iran", "Saudi Arabia", "Qatar", "Uzbekistan", "Jordan", "France", "Germany", "Spain", "Portugal", "England", "Netherlands",
        "Italy", "Croatia", "Belgium", "Switzerland", "Denmark", "Poland", "Serbia", "Sweden", "Austria", "Morocco", "Senegal", "Nigeria",
        "Cameroon", "Egypt", "South Africa", "Ghana", "Algeria", "Tunisia", "Ivory Coast", "New Zealand", "Costa Rica", "Panama", "United Arab Emirates", "Iraq","United States"
        ];

        vm.prank(owner);
        briVault.setCountry(newCountries);

        string memory countryNameNew = briVault.teams(countryIdToJoin);
        console.log("countryName: ", countryName);
        console.log("countryNameNew: ", countryNameNew);
        assertNotEq(countryName, countryNameNew);
        assertEq(briVault.userToCountry(user1), countryName);
        assertNotEq(briVault.userToCountry(user1), countryNameNew);

    }

    function testCancelPartecipationDoesNotRemoveAddressFromArray() public {
        uint256 depositAmount = 1 ether;
        uint256 countryIdToJoin = 4;
        vm.startPrank(user1);
        mockToken.approve(address(briVault), depositAmount);
        briVault.deposit(depositAmount, user1);  
        briVault.joinEvent(countryIdToJoin);  //slot 0
        assertEq(briVault.usersAddress(0), user1);

        vm.startPrank(user2);
        mockToken.approve(address(briVault), depositAmount);
        briVault.deposit(depositAmount, user2);   
        briVault.joinEvent(countryIdToJoin);  //slot 1
        assertEq(briVault.usersAddress(1), user2);

        vm.startPrank(user3);
        mockToken.approve(address(briVault), depositAmount);
        briVault.deposit(depositAmount, user3);   
        briVault.joinEvent(countryIdToJoin); //slot 2
        assertEq(briVault.usersAddress(2), user3);
        vm.stopPrank();

        vm.prank(user2);
        briVault.cancelParticipation();
        assertEq(briVault.usersAddress(1), user2);
    }


    function userCanManipulateTotalPartecipantSharesLoopingDepositAndCancelPartecipation() public {
        uint256 initialTotalShares = briVault.totalParticipantShares();
        assertEq(initialTotalShares, 0);

        uint256 depositAmount = 1 ether;
        uint256 expectedSharesForDeposit = briVault.convertToShares(depositAmount) *
         (10000 - participationFeeBsp) / 10000;
        
        uint256 loopIterations = 5;
        for(uint i = 1; i == loopIterations; i++){
            vm.startPrank(user1);
            mockToken.approve(address(briVault), depositAmount);
            briVault.deposit(depositAmount, user1);  
            briVault.joinEvent(1); 
            briVault.cancelParticipation();
            vm.stopPrank();
        }
        vm.startPrank(user1);
        mockToken.approve(address(briVault), depositAmount);
        briVault.deposit(depositAmount, user1);  
        briVault.joinEvent(1); 
        vm.stopPrank();
        //check shares effettive siano  giuste
        //check totalPartecipantShares è sbagliato
    }


    //DISABILITARE TRANSFER. DOPO CHE OWNER SET WINNER, CHI HA PERSO POTREBBE INVIARE SAHRES AL VINCITORE
    //CHE AVREBBE PIù SHARES DA DILUIRE NELLA VINCITA FINALE
    
}