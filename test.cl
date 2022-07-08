(* 
Constroi uma lista e imprime Ola Mundo!
Iremos testar o uso de classes e estrutura de dados
Assim como strings e comentarios
Tambem testamos sinais aritmeticos em formula
*)

class List inherits A2I {
	item: Object;
	proximo: List; -- Ponteiro para o resto da lista

	init(item_: Object, lista_: List) : List {
		{
			item <- item_;
			proximo <- lista_;
			self;
		}
	};

	flatten(): String {
		-- Testa tipo do objeto e converte em string
		let string : String <-
			case item of
				i : Int => i2a(i);
				s: String => s;
				o: Object => {abort(); "";}; -- Testando uso de abort
			esac
		in
			if (isvoid next) then 
				string
			else
				string.concat(proximo.flatten())
			fi
	};
	-- Funcao usada apenas para testar sinais
	formula(i : Int): Int {
		if (i < 0)
		then i * (10 - 4) / 3 + 15 ~ 5
		else i*(-1)
		fi
	};
};

class Main inherits IO {	
	-- Exemplo de multiplos bindings
	main() : Object { 
		let ola: String <- "Ola ",
			mundo: String <- "Mundo!",
			newline: String <- "\n"
			nil: List, -- Nao possuimos null em cool
			list: List (new List).init(ola, 
					(new List).init(mundo, 
						(new List).init(newline, nil))) 
		in
			string_saida(list.flatten())
	};
};
