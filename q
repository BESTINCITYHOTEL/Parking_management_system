<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
  <title>주차 관리 시스템</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      text-align: center;
      margin: 0;
      padding: 0;
    }

    .top-buttons {
      display: flex;
      justify-content: center;
      align-items: center;
      gap: 10px;
      margin-bottom: 10px;
    }

    .top-buttons button {
      font-size: 22px;
      background: none;
      border: none;
      cursor: pointer;
    }

    .parking-container {
      position: relative;
      width: 100%;
      max-width: 900px;
      height: 600px;
      margin: auto;
      display: grid;
      grid-template-columns: repeat(6, 1fr);
      grid-template-rows: repeat(18, 1fr);
      gap: 5px;
      background: url('도면이미지.png') no-repeat center center;
      background-size: cover;
    }

    .spot {
      width: 100%;
      height: 100%;
      aspect-ratio: 2 / 1;
      background-color: green;
      color: white;
      text-align: center;
      display: flex;
      justify-content: center;
      align-items: center;
      font-size: 12px;
      font-weight: bold;
      border-radius: 10px;
      cursor: pointer;
      line-height: 1.2;
      padding: 5px;
      text-shadow: 1px 1px 3px black;
      box-sizing: border-box;
      white-space: nowrap;
      position: relative;
    }

    .occupied {
      background-color: red;
    }

    .empty {
      background: none;
      pointer-events: none;
      border: 1px solid transparent;
    }

    .edit-mode .empty {
      background-color: #444;
      pointer-events: auto;
    }

    .edit-mode .empty::before {
      content: '+';
      color: white;
      font-size: 20px;
    }

    .edit-mode .spot.active:not(.occupied)::after {
      content: '-';
      position: absolute;
      top: 3px;
      right: 6px;
      font-size: 16px;
      color: white;
    }

    .border-top {
      border-top: 3px solid black;
    }

    .border-bottom {
      border-bottom: 3px solid black;
    }

    .modal {
      display: none;
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      background-color: rgba(0, 0, 0, 0.85);
      color: white;
      padding: 30px;
      border-radius: 10px;
      z-index: 1000;
      width: 90%;
      max-width: 450px;
      box-sizing: border-box;
    }

    .modal input {
      width: 100%;
      padding: 15px;
      margin: 5px 0;
      border: none;
      border-radius: 5px;
      font-size: 16px;
      box-sizing: border-box;
    }

    .modal-buttons {
      display: flex;
      justify-content: space-between;
      gap: 10px;
      margin-top: 10px;
    }

    .modal-buttons button {
      flex: 1;
      padding: 12px;
      font-size: 16px;
      border: none;
      border-radius: 5px;
      color: white;
      box-sizing: border-box;
    }

    .modal-buttons .remove {
      background-color: orange;
    }

    .modal-buttons .cancel {
      background-color: red;
    }

    .modal-buttons #submitBtn {
      background-color: green;
    }

    @media (max-width: 600px) {
      .parking-container {
        height: 400px;
      }

      .spot {
        font-size: 10px;
        padding: 3px;
      }

      .modal {
        width: 95%;
        padding: 20px;
      }

      .modal input {
        padding: 12px;
        font-size: 14px;
      }

      .modal-buttons button {
        padding: 10px;
        font-size: 14px;
      }
    }
  </style>
</head>
<body>
  <h2>주차 관리 시스템</h2>
  <div class="top-buttons">
    <button id="clearAllBtn">🧹</button>
    <button id="editModeBtn">🚗</button>
    <button id="resetToDefaultBtn" style="display:none">🔄</button>
  </div>
  <p id="status">현재 주차된 차량: 0대 / 남은 자리: 39대</p>

  <div class="parking-container" id="parkingLot"></div>

  <div id="modal" class="modal">
    <h3>주차 정보 수정</h3>
    <input type="text" id="room" placeholder="입실 호수" inputmode="numeric" />
    <input type="text" id="car" placeholder="차량 뒷번호" inputmode="numeric" />
    <div class="modal-buttons">
      <button class="remove" id="removeBtn">출차</button>
      <button id="submitBtn">저장</button>
      <button class="cancel" id="cancelBtn">취소</button>
    </div>
  </div>

  <script>
    const TOTAL_SPOTS = 108;
    const DEFAULT_ACTIVE_SPOTS = [
      1, 8, 15, 22, 26, 29, 37, 42, 43, 48,
      49, 52, 54, 55, 57, 58, 60, 61, 63, 64,
      66, 67, 69, 70, 72, 73, 75, 76, 78, 79,
      81, 82, 85, 87, 91, 97, 103, 106, 108
    ];

    let parkingRecords = JSON.parse(localStorage.getItem("parkingRecords") || "{}");
    let activeSpots = JSON.parse(localStorage.getItem("activeSpots") || JSON.stringify(DEFAULT_ACTIVE_SPOTS));
    let isEditMode = false;
    let modalOpen = false;
    let currentSlot = null;

    function updateStatus() {
      const occupiedCount = Object.keys(parkingRecords).length;
      const availableCount = activeSpots.length - occupiedCount;
      document.getElementById("status").innerText = `현재 주차된 차량: ${occupiedCount}대 / 남은 자리: ${availableCount}대`;
    }

    function showModal(slot) {
      modalOpen = true;
      currentSlot = slot;
      const modal = document.getElementById("modal");
      modal.style.display = "block";

      const roomInput = document.getElementById("room");
      const carInput = document.getElementById("car");
      roomInput.value = parkingRecords[slot]?.room || "";
      carInput.value = parkingRecords[slot]?.car || "";

      document.getElementById("submitBtn").onclick = () => {
        const room = roomInput.value;
        const car = carInput.value;
        parkingRecords[slot] = { room, car };
        const spotElement = document.getElementById(`spot-${slot}`);
        spotElement.classList.add("occupied");
        spotElement.innerText = `${room || "-"}\n${car || "-"}`;
        updateStatus();
        localStorage.setItem("parkingRecords", JSON.stringify(parkingRecords));
        modal.style.display = "none";
        modalOpen = false;
      };

      document.getElementById("removeBtn").onclick = () => {
        delete parkingRecords[slot];
        const spotElement = document.getElementById(`spot-${slot}`);
        spotElement.classList.remove("occupied");
        spotElement.innerText = "";
        updateStatus();
        localStorage.setItem("parkingRecords", JSON.stringify(parkingRecords));
        modal.style.display = "none";
        modalOpen = false;
      };

      document.getElementById("cancelBtn").onclick = () => {
        modal.style.display = "none";
        modalOpen = false;
      };
    }

    function toggleEditMode() {
      isEditMode = !isEditMode;
      document.getElementById("resetToDefaultBtn").style.display = isEditMode ? "inline-block" : "none";
      document.getElementById("parkingLot").classList.toggle("edit-mode", isEditMode);
    }

    function resetToDefaultSpots() {
      activeSpots = [...DEFAULT_ACTIVE_SPOTS];
      parkingRecords = {};
      localStorage.setItem("activeSpots", JSON.stringify(activeSpots));
      localStorage.setItem("parkingRecords", JSON.stringify(parkingRecords));
      createParkingLot();
    }

    function toggleParking(slot) {
      if (modalOpen) return;
      if (isEditMode) {
        const index = activeSpots.indexOf(slot);
        if (index === -1) {
          activeSpots.push(slot);
        } else {
          activeSpots.splice(index, 1);
          delete parkingRecords[slot];
        }
        localStorage.setItem("activeSpots", JSON.stringify(activeSpots));
        localStorage.setItem("parkingRecords", JSON.stringify(parkingRecords));
        createParkingLot();
      } else {
        if (activeSpots.includes(slot)) {
          showModal(slot);
        }
      }
    }

    function createParkingLot() {
      const lot = document.getElementById("parkingLot");
      lot.innerHTML = "";

      const linesBottom = [60, 70, 69, 81, 61, 73, 85, 97, 52];
      const linesTop = [66, 76, 75, 87, 67, 79, 91, 103, 58];

      for (let i = 1; i <= TOTAL_SPOTS; i++) {
        const spot = document.createElement("div");
        spot.classList.add("spot");

        if (!activeSpots.includes(i)) {
          spot.classList.add("empty");
        } else {
          spot.classList.add("active");
          spot.id = `spot-${i}`;
          if (parkingRecords[i]) {
            spot.classList.add("occupied");
            spot.innerText = `${parkingRecords[i].room || "-"}\n${parkingRecords[i].car || "-"}`;
          }
        }

        if (linesBottom.includes(i)) spot.classList.add("border-bottom");
        if (linesTop.includes(i)) spot.classList.add("border-top");

        spot.onclick = () => toggleParking(i);
        lot.appendChild(spot);
      }
      updateStatus();
    }

    document.getElementById("editModeBtn").onclick = toggleEditMode;
    document.getElementById("resetToDefaultBtn").onclick = resetToDefaultSpots;
    document.getElementById("clearAllBtn").onclick = () => {
      parkingRecords = {};
      localStorage.setItem("parkingRecords", JSON.stringify(parkingRecords));
      createParkingLot();
    };

    createParkingLot();
  </script>
</body>
</html>
