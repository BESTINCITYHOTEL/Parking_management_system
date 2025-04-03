document.getElementById("pasteBtn").addEventListener("click", async () => {
    try {
        // 클립보드에서 데이터 읽기
        const text = await navigator.clipboard.readText();
        processPastedData(text);
    } catch (err) {
        alert("클립보드에서 데이터를 가져오는데 실패했습니다.");
    }
});

function processPastedData(text) {
    const lines = text.split("\n");
    let pastedData = [];

    lines.forEach(line => {
        const parts = line.split("\t"); // 탭 기준으로 데이터 구분
        if (parts.length >= 2) {
            const roomNumber = parts[0].trim(); // 첫 번째 값이 입실 호수
            const carMatch = line.match(/차량:?(\d{4})/); // 차량 번호 추출 (4자리 숫자)
            const carNumber = carMatch ? carMatch[1] : "";

            pastedData.push({ roomNumber, carNumber });
        }
    });

    validateAndInsertData(pastedData);
}

function validateAndInsertData(pastedData) {
    let existingData = getExistingParkingData();
    let alerts = [];
    let roomToCars = {};
    let existingEntries = new Set();
    let existingRooms = new Map();  // 기존 데이터의 방 번호 저장
    let existingCars = new Map();   // 기존 데이터의 차량 번호 저장

    // 기존 데이터 Set 및 Map에 저장
    existingData.forEach(entry => {
        let entryKey = `${entry.roomNumber}-${entry.carNumber}`;
        existingEntries.add(entryKey);

        if (entry.roomNumber) {
            existingRooms.set(entry.roomNumber, entry.carNumber);
        }
        if (entry.carNumber) {
            existingCars.set(entry.carNumber, entry.roomNumber);
        }
    });

    pastedData.forEach(entry => {
        let { roomNumber, carNumber } = entry;
        let entryKey = `${roomNumber}-${carNumber}`;

        // 🚨 1. 데이터가 없으면 무시
        if (!roomNumber && !carNumber) return;

        // 🚨 2. 같은 데이터가 이미 등록된 경우
        if (existingEntries.has(entryKey)) {
            alerts.push(`⚠️ 중복 입력 방지: 방 ${roomNumber} - 차량 ${carNumber} 이미 등록됨`);
            return;
        }

        // 🚨 3. 다른 방에 같은 차량 번호가 있는 경우
        if (existingCars.has(carNumber) && existingCars.get(carNumber) !== roomNumber) {
            alerts.push(`⚠️ 차량 번호 ${carNumber}가 방 ${existingCars.get(carNumber)}에도 등록됨. 수동 확인 필요`);
        }

        // 🚨 4. 입실 호수에 차량 번호 2개 이상 있는 경우 체크
        if (roomNumber) {
            roomToCars[roomNumber] = roomToCars[roomNumber] || [];
            roomToCars[roomNumber].push(carNumber);
        }

        // 🚨 5. 기존 정보와 비교 (입실 호수 & 차량 번호 일치 여부)
        if (existingRooms.has(roomNumber)) {
            let existingCar = existingRooms.get(roomNumber);
            if (existingCar !== carNumber) {
                alerts.push(`⚠️ 방 ${roomNumber}의 기존 차량 번호 ${existingCar}와 충돌 (새로운 차량: ${carNumber}). 수동 입력 바람.`);
            }
        } 
        if (existingCars.has(carNumber)) {
            let existingRoom = existingCars.get(carNumber);
            if (existingRoom !== roomNumber) {
                alerts.push(`⚠️ 차량 ${carNumber}의 기존 방 번호 ${existingRoom}와 충돌 (새로운 방: ${roomNumber}). 수동 입력 바람.`);
            }
        }

        // 🚨 6. 차량 번호만 있고 방 번호가 없는 경우
        if (carNumber && !roomNumber) {
            alerts.push(`🚗 미입실 차량: ${carNumber} (수동 입력 필요)`);
        }

        // 🚨 7. 새로운 데이터 추가
        insertNewEntry(roomNumber, carNumber);
        existingEntries.add(entryKey);
        if (roomNumber) existingRooms.set(roomNumber, carNumber);
        if (carNumber) existingCars.set(carNumber, roomNumber);
    });

    // 🚨 8. 입실 호수 하나에 차량 번호 2개 이상 있는 경우 경고
    Object.keys(roomToCars).forEach(room => {
        if (roomToCars[room].length > 1) {
            alerts.push(`⚠️ 방 ${room}에 차량 ${roomToCars[room].join(", ")} 개 있음 (수동 입력 필요)`);
        }
    });

    // 🚨 9. 최종 경고 메시지 출력
    if (alerts.length > 0) {
        alert(alerts.join("\n"));
    }
}
