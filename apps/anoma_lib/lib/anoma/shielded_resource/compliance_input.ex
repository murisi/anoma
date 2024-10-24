defmodule Anoma.ShieldedResource.ComplianceInput do
  @moduledoc """
  I represent a compliance's input.
  """

  alias __MODULE__
  use TypedStruct

  alias Anoma.ShieldedResource

  typedstruct enforce: true do
    # Input resource
    field(:input_resource, ShieldedResource.t())
    # Input resource merkle path
    field(:merkel_proof, CommitmentTree.Proof.t())
    # Nullifier key of the input resource
    field(:input_nf_key, binary(), default: <<0::256>>)
    # Ephemeral root
    field(:eph_root, binary(), default: <<0::256>>)
    # Output resource
    field(:output_resource, ShieldedResource.t())
    # Random value in delta proof(binding signature)
    field(:rcv, binary(), default: <<0::256>>)
  end

  @doc "Generate the compliance input json"
  def to_json_string(input = %ComplianceInput{}) do
    {_, _, path} =
      Enum.reduce(
        1..32,
        {input.merkel_proof.path, input.merkel_proof.proof, []},
        fn _, {path, proof, acc} ->
          {Integer.floor_div(path, 2), elem(proof, Integer.mod(path, 2)),
           [
             elem(proof, Integer.mod(path + 1, 2)) |> :binary.bin_to_list()
             | acc
           ]}
        end
      )

    Cairo.generate_compliance_input_json(
      ShieldedResource.to_bytes(input.input_resource),
      ShieldedResource.to_bytes(input.output_resource),
      path,
      input.merkel_proof.path,
      input.input_nf_key |> :binary.bin_to_list(),
      input.eph_root |> :binary.bin_to_list(),
      input.rcv |> :binary.bin_to_list()
    )
  end
end
