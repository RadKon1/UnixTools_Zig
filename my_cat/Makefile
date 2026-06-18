# --- Konfiguracja (opcjonalna) ---
# Jeśli chcesz przekazywać dodatkowe flagi, możesz je definiować tutaj
ZIG_FLAGS ?=

.PHONY: all build release run test fmt clean update

# Domyślny cel uruchamiany po wpisaniu samego "make"
all: build

# 1. Standardowe budowanie (tryb Debug)
# Polega na wbudowanym systemie build.zig
build:
	zig build $(ZIG_FLAGS)

# 2. Budowanie zoptymalizowane do wydania (tryb ReleaseSafe lub ReleaseFast)
release:
	zig build -Doptimize=ReleaseSafe $(ZIG_FLAGS)

# 3. Natychmiastowe uruchomienie projektu
run:
	zig build run $(ZIG_FLAGS)

# 4. Uruchomienie wszystkich testów zdefiniowanych w projekcie
test:
	zig build test $(ZIG_FLAGS)

# 5. Automatyczne formatowanie całego kodu w folderze źródłowym (zazwyczaj src/)
fmt:
	zig fmt build.zig

# 6. Aktualizacja zależności w pliku build.zig.zon (Zig 0.12+)
update:
	zig fetch --all

# 7. Sprzątanie plików tymczasowych i skompilowanych binarek
# Usuwa foldery generowane domyślnie przez kompilator Ziga
clean:
	rm -rf .zig-cache zig-out
